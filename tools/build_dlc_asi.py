#!/usr/bin/env python3
"""Generate dlc_enable.asi — DLC Content Activator for Mercenaries 2.

This script generates a minimal 32-bit Windows DLL (renamed to .asi) that:
  1. Hooks IsOnlineConnected() → always returns true (EA servers bypass)
  2. Hooks IsDLC() → always returns true (DLC session flag)
  3. Hooks IsMatchmakingInternet() → always returns true

The DLL is loaded by ThirteenAG's Ultimate ASI Loader (dinput8.dll proxy)
alongside cruise.asi (SecuROM bypass).

Like tools/remove_securom.py's generate_cruise_dll(), this generates a
complete valid PE from Python using struct.pack — no C compiler needed.

Usage:
  python3 tools/build_dlc_asi.py [--output <path>]
  python3 tools/build_dlc_asi.py --output "path/to/game/scripts/dlc_enable.asi"

The generated DLL performs runtime memory scanning of the game's .rdata
section to find Lua registration table entries, then patches the function
pointers to redirect to our hook functions embedded in the DLL's code section.

Architecture: PE32 (i386), DLL, 4 sections (CODE/DATA/.idata/.reloc)
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path


def generate_dlc_enable_asi() -> bytes:
    """Generate dlc_enable.asi — a minimal PE DLL that hooks Lua functions.

    The DLL's DllMain spawns a thread that:
      1. Sleeps 5 seconds (wait for game Lua init)
      2. Scans .rdata (0x00B05000..0x00BF5FFF) for target string addresses
      3. For each found string, locates the adjacent C function pointer
      4. Overwrites the function pointer in the luaL_Reg table with our hook
      5. The hook function pushes boolean true to the Lua stack and returns 1

    The hook functions use direct Lua 5.1 stack manipulation:
      - lua_State + 8 = top pointer (StkId, points to next free TValue)
      - TValue = { int/float value (4 bytes), int tt (4 bytes) } = 8 bytes
      - LUA_TBOOLEAN type tag = 1
      - Push: *top = {1, 1}; top++; return 1

    This approach avoids needing to resolve lua_pushboolean from the EXE.
    """
    IMAGE_BASE = 0x10000000  # Non-conflicting base for a DLL
    SECTION_ALIGN = 0x1000
    FILE_ALIGN = 0x200

    # File layout:
    # Headers:  0x000..0x3FF (0x400 bytes)
    # CODE:     0x400..0xBFF (0x800 bytes, RVA 0x1000)
    # DATA:     0xC00..0xDFF (0x200 bytes, RVA 0x2000)
    # .idata:   0xE00..0xFFF (0x200 bytes, RVA 0x3000)
    # .reloc:   0x1000..0x11FF (0x200 bytes, RVA 0x4000)
    # Total: 0x1200 bytes, padded to 0x1400

    CODE_RVA = 0x1000
    CODE_FILE = 0x400
    CODE_RAW_SIZE = 0x800
    DATA_RVA = 0x2000
    DATA_FILE = 0xC00
    DATA_RAW_SIZE = 0x200
    IDATA_RVA = 0x3000
    IDATA_FILE = 0xE00
    IDATA_RAW_SIZE = 0x200
    RELOC_RVA = 0x4000
    RELOC_FILE = 0x1000
    RELOC_RAW_SIZE = 0x200

    SIZE_OF_IMAGE = 0x5000
    FILE_SIZE = 0x1200

    # --- Virtual addresses for data references ---
    # DATA section layout:
    #   +0x000: "IsOnlineConnected\0"       (18 bytes)
    #   +0x014: "IsDLC\0"                   (6 bytes)
    #   +0x01C: "IsMatchmakingInternet\0"   (22 bytes)
    #   +0x034: padding
    #   +0x040: target_strings[3] (3 × DWORD: resolved string VAs, filled at runtime)
    #   +0x04C: scan state / flags

    STR_ISONLINE_OFF = 0x000
    STR_ISDLC_OFF = 0x014
    STR_ISMATCH_OFF = 0x01C

    STR_ISONLINE_VA = IMAGE_BASE + DATA_RVA + STR_ISONLINE_OFF
    STR_ISDLC_VA = IMAGE_BASE + DATA_RVA + STR_ISDLC_OFF
    STR_ISMATCH_VA = IMAGE_BASE + DATA_RVA + STR_ISMATCH_OFF

    # IAT layout in .idata:
    # We need: VirtualProtect, Sleep, CreateThread, GetModuleHandleA,
    #          FlushInstructionCache, GetCurrentProcess, DisableThreadLibraryCalls
    IAT_VA = IMAGE_BASE + IDATA_RVA + 0x44

    # Function indices in IAT (each 4 bytes)
    IAT_VIRTUAL_PROTECT = IAT_VA + 0
    IAT_SLEEP = IAT_VA + 4
    IAT_CREATE_THREAD = IAT_VA + 8
    IAT_FLUSH_ICACHE = IAT_VA + 12
    IAT_GET_CURRENT_PROCESS = IAT_VA + 16
    IAT_DISABLE_THREAD_CALLS = IAT_VA + 20

    # --- Build the code section ---
    code = bytearray(CODE_RAW_SIZE)
    relocs: list[int] = []  # offsets within CODE section needing relocation
    i = 0

    # ============================================================
    # HOOK FUNCTION: Hook_ReturnTrue (at code offset 0)
    # This is a Lua CFunction that pushes boolean true and returns 1.
    # Signature: int Hook_ReturnTrue(lua_State* L)
    #
    # lua_State* L is at [esp+4] (cdecl, but Lua uses it as stdcall-ish)
    # lua_State->top is at L+8
    # TValue = { int value, int tt } = 8 bytes
    # LUA_TBOOLEAN = 1
    # ============================================================
    hook_return_true_offset = i

    # mov eax, [esp+4]           ; eax = L
    code[i:i+4] = b"\x8B\x44\x24\x04"
    i += 4

    # mov ecx, [eax+8]           ; ecx = L->top (pointer to TValue)
    code[i:i+3] = b"\x8B\x48\x08"
    i += 3

    # mov dword [ecx+0], 1       ; top->value = 1 (true)
    code[i:i+2] = b"\xC7\x01"
    i += 2
    struct.pack_into("<I", code, i, 1)
    i += 4

    # mov dword [ecx+4], 1       ; top->tt = LUA_TBOOLEAN (1)
    code[i:i+3] = b"\xC7\x41\x04"
    i += 3
    struct.pack_into("<I", code, i, 1)
    i += 4

    # add dword [eax+8], 8       ; L->top++ (advance by sizeof(TValue)=8)
    code[i:i+3] = b"\x83\x40\x08"
    i += 3
    code[i] = 0x08
    i += 1

    # mov eax, 1                 ; return 1 (one result pushed)
    code[i:i+5] = b"\xB8\x01\x00\x00\x00"
    i += 5

    # ret                        ; Lua CFunction returns to caller
    code[i] = 0xC3
    i += 1

    hook_return_true_va = IMAGE_BASE + CODE_RVA + hook_return_true_offset

    # ============================================================
    # INIT THREAD FUNCTION (at code offset ~0x1C)
    # Called by CreateThread from DllMain.
    # 1. Sleep(5000)
    # 2. Scan .rdata for each target string
    # 3. For each match, find the luaL_Reg entry and patch func ptr
    # ============================================================
    # Align to 16 bytes
    i = (i + 15) & ~15
    init_thread_offset = i

    # --- push ebp / mov ebp, esp / sub esp, 0x20 (local vars) ---
    code[i] = 0x55; i += 1                    # push ebp
    code[i:i+2] = b"\x8B\xEC"; i += 2        # mov ebp, esp
    code[i:i+3] = b"\x83\xEC\x20"; i += 3    # sub esp, 0x20

    # --- Sleep(5000) ---
    # push 5000
    code[i] = 0x68; i += 1
    struct.pack_into("<I", code, i, 5000)
    i += 4
    # call [IAT_SLEEP]
    code[i:i+2] = b"\xFF\x15"; i += 2
    struct.pack_into("<I", code, i, IAT_SLEEP)
    relocs.append(i)
    i += 4

    # --- Scan loop setup ---
    # Game .rdata: start=0x00B05000, size=0x000F1000
    GAME_RDATA_START = 0x00B05000
    GAME_RDATA_SIZE = 0x000F1000
    GAME_TEXT_START = 0x00401000
    GAME_TEXT_END = 0x00B04FFF

    # We'll scan for 3 strings. For each one:
    #   1. Scan .rdata for the string bytes
    #   2. Once found, scan .rdata for a DWORD == found_address
    #   3. Check if the next DWORD points into .text
    #   4. If so, VirtualProtect + overwrite with hook_return_true_va

    # String targets are stored in DATA section.
    # We process them in a loop: 3 iterations, string offsets at DATA+0, DATA+0x14, DATA+0x1C

    # mov esi, GAME_RDATA_START  ; esi = scan base
    code[i] = 0xBE; i += 1
    struct.pack_into("<I", code, i, GAME_RDATA_START)
    i += 4

    # For simplicity in this minimal PE, we'll inline the scan for each
    # of the 3 target strings rather than implementing a generic loop.
    # This keeps the code straightforward and avoids complex control flow.

    # ---- Scan for "IsOnlineConnected" (18 chars + null = 19 bytes) ----
    # Strategy: Find the string in game .rdata, get its VA, then find
    # the luaL_Reg table entry pointing to it.
    #
    # Approach: Use a simpler method — scan for the KNOWN string VA from
    # our EXE analysis. If the string is at the expected offset, we can
    # directly look for cross-references. If not, do a full scan.
    #
    # Known string VAs (from docs/exe_analysis_agent_a.md):
    #   "IsOnlineConnected" — we need to find it dynamically since different
    #   EXE versions may differ slightly.
    #
    # Simplified approach for the generated ASI:
    # Scan all of .rdata. For each 4-byte-aligned DWORD that points into
    # .rdata (could be a string pointer), check if the target string starts
    # there. If so, that's our string VA. Then find where .rdata has a
    # pointer TO that VA followed by a pointer into .text.

    # Given the complexity of implementing a full string scanner in raw x86
    # machine code within a PE generator, we use a HYBRID approach:
    #
    # The DLL has a table of KNOWN string VAs (from EXE analysis) as primary
    # lookup, with a fallback brute-force scan. This is practical because
    # the cracked EXE has a fixed layout.

    # ---- PRIMARY PATH: Use known addresses ----
    # For the cracked EXE (53,482,288 bytes, MD5 857b3387d54774a32c1328effb5de4d4):
    # All strings are at known VAs. We scan .rdata for DWORDs matching these
    # VAs, find the adjacent function pointer, and patch it.

    # We'll implement: for each known_string_va, scan .rdata for it
    # Known VAs (from file offsets + image base 0x400000):
    # "IsOnlineConnected" — need to find dynamically (search for string bytes)

    # ACTUALLY: The cleanest approach for a Python-generated PE is to emit
    # machine code that does the string search. But that's complex.
    #
    # BETTER APPROACH: Since we know the exact EXE layout, embed the expected
    # function addresses and patch them directly. Include a verification step.
    #
    # From the EXE analysis, IsOnlineConnected is in the Net Lua table.
    # The registration table at ~0x00798770 has entries like:
    #   {"IsOnlineConnected", 0x005EXXXX}
    #
    # We'll implement a generic "find string in memory, then find xref" approach.

    # ---- IMPLEMENTATION: Generic .rdata scanner ----
    # Since encoding a full C-like scanner in raw x86 is complex for a
    # Python PE generator, we take the pragmatic approach:
    #
    # 1. DllMain spawns a thread
    # 2. The thread does a simple scan using minimal x86 code
    # 3. We encode the pattern: find DWORD in .rdata that equals target,
    #    check next DWORD is in .text range, if so VirtualProtect + patch
    #
    # The "target" is the VA of each string. We find the string VA first
    # by scanning for its bytes, then search for xrefs.

    # For a Python-generated PE, the most maintainable approach is:
    # Encode the scan as a series of REP SCASB / REPE CMPSB operations.
    # But given the constraints, let's use the KNOWN OFFSETS approach
    # with runtime verification.

    # Reset code pointer — we'll use a different, cleaner strategy
    i = init_thread_offset + 6  # After prolog

    # Sleep(5000) — already emitted above, re-emit from correct position
    # (We already emitted Sleep above at the right spot, let's continue from there)
    # Actually let's restart the init thread code cleanly:
    i = init_thread_offset
    code[i] = 0x55; i += 1                    # push ebp
    code[i:i+2] = b"\x8B\xEC"; i += 2        # mov ebp, esp
    code[i:i+3] = b"\x83\xEC\x30"; i += 3    # sub esp, 0x30

    # push ebx / push esi / push edi (callee-saved)
    code[i] = 0x53; i += 1
    code[i] = 0x56; i += 1
    code[i] = 0x57; i += 1

    # Sleep(5000) — wait for game init
    code[i] = 0x68; i += 1
    struct.pack_into("<I", code, i, 5000); i += 4
    code[i:i+2] = b"\xFF\x15"; i += 2
    struct.pack_into("<I", code, i, IAT_SLEEP)
    relocs.append(i); i += 4

    # ---- Scan for each target string and patch its registration entry ----
    # We'll emit code for 3 patch targets.
    # Strategy per target:
    #   edi = GAME_RDATA_START
    #   ecx = GAME_RDATA_SIZE / 4  (scan DWORDs)
    #   For each DWORD at [edi]:
    #     Load it into eax
    #     Check if memory at eax starts with our target string
    #     If yes: found string VA = eax
    #       Now scan .rdata again for a DWORD == eax
    #       Where we find it, check [addr+4] is in .text range
    #       If so: VirtualProtect + write hook_return_true_va
    #
    # This is too complex for inline assembly in a PE generator.
    # Let's use the SIMPLEST possible approach:

    # SIMPLEST APPROACH:
    # The game's .rdata has luaL_Reg entries: {string_ptr, func_ptr}
    # We scan .rdata for pairs where:
    #   - First DWORD points somewhere in .rdata (where a target string is)
    #   - The memory at that pointer matches our target string
    #   - Second DWORD points into .text (0x00401000..0x00B04FFF)
    # When found, overwrite the second DWORD with our hook function VA.
    #
    # In x86 this is a nested loop, which is doable:

    # ---- Macro: scan_and_patch(target_string_va_in_data, target_len) ----
    # We'll emit this pattern 3 times (once per hook target).

    def emit_scan_and_patch(code: bytearray, i: int, relocs: list,
                            data_str_va: int, str_len: int) -> int:
        """Emit x86 code to find a string in game .rdata and patch its reg entry.

        Algorithm:
          edi = GAME_RDATA_START
          while edi < GAME_RDATA_START + GAME_RDATA_SIZE - str_len:
            if memcmp(edi, data_str_va, str_len) == 0:
              found_string_va = edi
              // Now scan for xref
              esi = GAME_RDATA_START
              while esi < GAME_RDATA_START + GAME_RDATA_SIZE - 8:
                if [esi] == found_string_va:
                  func_ptr = [esi+4]
                  if func_ptr >= 0x00401000 and func_ptr < 0x00B05000:
                    VirtualProtect(esi+4, 4, PAGE_READWRITE, &old)
                    [esi+4] = hook_return_true_va
                    VirtualProtect(esi+4, 4, old, &dummy)
                    goto done
                esi += 4
            edi += 1
          done:
        """
        loop_start = i

        # mov edi, GAME_RDATA_START
        code[i] = 0xBF; i += 1
        struct.pack_into("<I", code, i, GAME_RDATA_START); i += 4

        # mov ebx, GAME_RDATA_START + GAME_RDATA_SIZE - str_len  (end boundary)
        scan_end = GAME_RDATA_START + GAME_RDATA_SIZE - str_len
        code[i] = 0xBB; i += 1
        struct.pack_into("<I", code, i, scan_end); i += 4

        # outer_loop:
        outer_loop = i

        # cmp edi, ebx
        code[i:i+2] = b"\x39\xDF"; i += 2  # cmp edi, ebx
        # jge done (will patch offset later)
        code[i] = 0x7D; i += 1
        jge_done_pos = i; i += 1  # placeholder for rel8

        # --- Compare string at [edi] with our target ---
        # push edi / push data_str_va / push str_len / call memcmp equivalent
        # Simpler: use repe cmpsb inline

        # Save edi
        code[i] = 0x52; i += 1  # push edx (save)

        # mov esi, data_str_va (our copy of the target string in DATA)
        code[i] = 0xBE; i += 1
        struct.pack_into("<I", code, i, data_str_va)
        relocs.append(i); i += 4

        # mov ecx, str_len
        code[i] = 0xB9; i += 1
        struct.pack_into("<I", code, i, str_len); i += 4

        # Save edi for after comparison
        # push edi
        code[i] = 0x57; i += 1

        # repe cmpsb
        code[i:i+2] = b"\xF3\xA6"; i += 2

        # pop edi (restore)
        code[i] = 0x5F; i += 1
        # pop edx
        code[i] = 0x5A; i += 1

        # jne next_byte
        code[i] = 0x75; i += 1
        jne_next_pos = i; i += 1  # placeholder

        # --- Found the string! edi = string VA in game memory ---
        # Now scan .rdata for a DWORD == edi (the xref)
        # mov esi, GAME_RDATA_START
        code[i] = 0xBE; i += 1
        struct.pack_into("<I", code, i, GAME_RDATA_START); i += 4

        # mov edx, GAME_RDATA_START + GAME_RDATA_SIZE - 8
        xref_end = GAME_RDATA_START + GAME_RDATA_SIZE - 8
        code[i] = 0xBA; i += 1
        struct.pack_into("<I", code, i, xref_end); i += 4

        # xref_loop:
        xref_loop = i

        # cmp esi, edx
        code[i:i+2] = b"\x39\xD6"; i += 2  # cmp esi, edx
        # jge outer_next (string found but no xref — skip)
        code[i] = 0x7D; i += 1
        jge_outer_next_pos = i; i += 1

        # cmp [esi], edi
        code[i:i+2] = b"\x39\x3E"; i += 2  # cmp [esi], edi
        # jne xref_next
        code[i] = 0x75; i += 1
        jne_xref_next_pos = i; i += 1

        # --- Found xref! Check [esi+4] is in .text range ---
        # mov eax, [esi+4]
        code[i:i+3] = b"\x8B\x46\x04"; i += 3

        # cmp eax, 0x00401000
        code[i] = 0x3D; i += 1
        struct.pack_into("<I", code, i, GAME_TEXT_START); i += 4
        # jb xref_next
        code[i] = 0x72; i += 1
        jb_xref_next_pos = i; i += 1

        # cmp eax, 0x00B05000
        code[i] = 0x3D; i += 1
        struct.pack_into("<I", code, i, GAME_TEXT_END + 1); i += 4
        # jae xref_next
        code[i] = 0x73; i += 1
        jae_xref_next_pos = i; i += 1

        # --- Valid function pointer! Patch it ---
        # lea eax, [esi+4]  ; address to patch
        code[i:i+3] = b"\x8D\x46\x04"; i += 3

        # VirtualProtect(eax, 4, PAGE_READWRITE=0x04, &ebp-4)
        # push ebp-4 (lpflOldProtect)
        code[i:i+3] = b"\x8D\x4D\xFC"; i += 3  # lea ecx, [ebp-4]
        code[i] = 0x51; i += 1  # push ecx
        # push 0x04 (PAGE_READWRITE)
        code[i:i+2] = b"\x6A\x04"; i += 2
        # push 4 (dwSize)
        code[i:i+2] = b"\x6A\x04"; i += 2
        # push eax (lpAddress)
        code[i] = 0x50; i += 1
        # call [IAT_VIRTUAL_PROTECT]
        code[i:i+2] = b"\xFF\x15"; i += 2
        struct.pack_into("<I", code, i, IAT_VIRTUAL_PROTECT)
        relocs.append(i); i += 4

        # Now write the hook address: mov dword [esi+4], hook_return_true_va
        code[i:i+2] = b"\xC7\x46"; i += 2
        code[i] = 0x04; i += 1  # [esi+4]
        struct.pack_into("<I", code, i, hook_return_true_va)
        relocs.append(i); i += 4

        # Restore protection:
        # VirtualProtect(esi+4, 4, [ebp-4], &ebp-8)
        code[i:i+3] = b"\x8D\x4D\xF8"; i += 3  # lea ecx, [ebp-8]
        code[i] = 0x51; i += 1  # push ecx
        code[i:i+3] = b"\xFF\x75\xFC"; i += 3  # push [ebp-4] (old protect)
        code[i:i+2] = b"\x6A\x04"; i += 2  # push 4
        # lea eax, [esi+4]
        code[i:i+3] = b"\x8D\x46\x04"; i += 3
        code[i] = 0x50; i += 1  # push eax
        code[i:i+2] = b"\xFF\x15"; i += 2
        struct.pack_into("<I", code, i, IAT_VIRTUAL_PROTECT)
        relocs.append(i); i += 4

        # FlushInstructionCache(GetCurrentProcess(), NULL, 0)
        code[i:i+2] = b"\x6A\x00"; i += 2  # push 0
        code[i:i+2] = b"\x6A\x00"; i += 2  # push 0
        # call [IAT_GET_CURRENT_PROCESS]
        code[i:i+2] = b"\xFF\x15"; i += 2
        struct.pack_into("<I", code, i, IAT_GET_CURRENT_PROCESS)
        relocs.append(i); i += 4
        code[i] = 0x50; i += 1  # push eax
        code[i:i+2] = b"\xFF\x15"; i += 2
        struct.pack_into("<I", code, i, IAT_FLUSH_ICACHE)
        relocs.append(i); i += 4

        # jmp done
        code[i] = 0xEB; i += 1
        jmp_done_pos = i; i += 1

        # xref_next:
        xref_next = i
        code[jne_xref_next_pos] = xref_next - (jne_xref_next_pos + 1)
        code[jb_xref_next_pos] = xref_next - (jb_xref_next_pos + 1)
        code[jae_xref_next_pos] = xref_next - (jae_xref_next_pos + 1)

        # add esi, 4
        code[i:i+3] = b"\x83\xC6\x04"; i += 3
        # jmp xref_loop
        code[i] = 0xEB; i += 1
        code[i] = (xref_loop - (i + 1)) & 0xFF; i += 1

        # outer_next: (after string match xref scan completes without finding valid entry)
        outer_next = i
        code[jge_outer_next_pos] = outer_next - (jge_outer_next_pos + 1)

        # next_byte: (string didn't match, advance edi)
        next_byte = i
        code[jne_next_pos] = next_byte - (jne_next_pos + 1)

        # inc edi
        code[i] = 0x47; i += 1
        # jmp outer_loop
        rel = (outer_loop - (i + 2)) & 0xFF
        if outer_loop < i:
            # backward jump
            code[i] = 0xEB; i += 1
            code[i] = (outer_loop - (i + 1)) & 0xFF; i += 1
        else:
            code[i] = 0xEB; i += 1
            code[i] = rel; i += 1

        # done:
        done = i
        code[jge_done_pos] = done - (jge_done_pos + 1)
        code[jmp_done_pos] = done - (jmp_done_pos + 1)

        return i

    # Emit scan-and-patch for "IsOnlineConnected" (17 chars + null = 18)
    i = emit_scan_and_patch(code, i, relocs, STR_ISONLINE_VA, 18)

    # Emit scan-and-patch for "IsDLC" (5 chars + null = 6)
    i = emit_scan_and_patch(code, i, relocs, STR_ISDLC_VA, 6)

    # Emit scan-and-patch for "IsMatchmakingInternet" (21 chars + null = 22)
    i = emit_scan_and_patch(code, i, relocs, STR_ISMATCH_VA, 22)

    # --- Epilog: pop / leave / ret ---
    code[i] = 0x5F; i += 1  # pop edi
    code[i] = 0x5E; i += 1  # pop esi
    code[i] = 0x5B; i += 1  # pop ebx
    code[i:i+2] = b"\x8B\xE5"; i += 2  # mov esp, ebp (leave)
    code[i] = 0x5D; i += 1  # pop ebp
    # ret 4 (WINAPI stdcall: lpParameter on stack)
    code[i:i+3] = b"\xC2\x04\x00"; i += 3

    init_thread_va = IMAGE_BASE + CODE_RVA + init_thread_offset

    # ============================================================
    # DllMain (at next aligned offset)
    # ============================================================
    i = (i + 15) & ~15
    dllmain_offset = i

    # DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
    # if (fdwReason == DLL_PROCESS_ATTACH) { ... }
    # return TRUE;

    # push ebp / mov ebp, esp
    code[i] = 0x55; i += 1
    code[i:i+2] = b"\x8B\xEC"; i += 2

    # cmp dword [ebp+12], 1  (fdwReason == DLL_PROCESS_ATTACH)
    code[i:i+4] = b"\x83\x7D\x0C\x01"; i += 4
    # jne skip_init
    code[i] = 0x75; i += 1
    jne_skip_pos = i; i += 1

    # --- DLL_PROCESS_ATTACH ---
    # DisableThreadLibraryCalls(hinstDLL)
    code[i:i+3] = b"\xFF\x75\x08"; i += 3  # push [ebp+8] (hinstDLL)
    code[i:i+2] = b"\xFF\x15"; i += 2
    struct.pack_into("<I", code, i, IAT_DISABLE_THREAD_CALLS)
    relocs.append(i); i += 4

    # CreateThread(NULL, 0, InitThread, NULL, 0, NULL)
    code[i:i+2] = b"\x6A\x00"; i += 2  # push 0 (lpThreadId)
    code[i:i+2] = b"\x6A\x00"; i += 2  # push 0 (dwCreationFlags)
    code[i:i+2] = b"\x6A\x00"; i += 2  # push 0 (lpParameter)
    # push init_thread_va
    code[i] = 0x68; i += 1
    struct.pack_into("<I", code, i, init_thread_va)
    relocs.append(i); i += 4
    code[i:i+2] = b"\x6A\x00"; i += 2  # push 0 (dwStackSize)
    code[i:i+2] = b"\x6A\x00"; i += 2  # push 0 (lpThreadAttributes)
    # call [IAT_CREATE_THREAD]
    code[i:i+2] = b"\xFF\x15"; i += 2
    struct.pack_into("<I", code, i, IAT_CREATE_THREAD)
    relocs.append(i); i += 4

    # skip_init:
    skip_init = i
    code[jne_skip_pos] = skip_init - (jne_skip_pos + 1)

    # mov eax, 1 (return TRUE)
    code[i:i+5] = b"\xB8\x01\x00\x00\x00"; i += 5

    # pop ebp / ret 12 (stdcall, 3 params)
    code[i] = 0x5D; i += 1
    code[i:i+3] = b"\xC2\x0C\x00"; i += 3

    dllmain_rva = CODE_RVA + dllmain_offset

    # Verify code fits
    assert i <= CODE_RAW_SIZE, f"Code section overflow: {i} > {CODE_RAW_SIZE}"

    # --- DATA section ---
    data_sec = bytearray(DATA_RAW_SIZE)
    # Target strings for memory scanning
    s = b"IsOnlineConnected\x00"
    data_sec[STR_ISONLINE_OFF:STR_ISONLINE_OFF + len(s)] = s
    s = b"IsDLC\x00"
    data_sec[STR_ISDLC_OFF:STR_ISDLC_OFF + len(s)] = s
    s = b"IsMatchmakingInternet\x00"
    data_sec[STR_ISMATCH_OFF:STR_ISMATCH_OFF + len(s)] = s

    # --- .idata section (imports from KERNEL32.dll) ---
    idata_sec = bytearray(IDATA_RAW_SIZE)

    # Layout within .idata (RVA base = IDATA_RVA = 0x3000):
    #   0x00..0x13: IDT[0] — KERNEL32.dll entry (20 bytes)
    #   0x14..0x27: IDT[1] — null terminator (20 zero bytes)
    #   0x28..0x3F: OFT array (6 entries + null = 28 bytes)
    #   0x44..0x5F: IAT array (6 entries + null = 28 bytes)
    #   0x60..0x6F: DLL name "KERNEL32.dll\0"
    #   0x70+:      Hint/Name entries

    OFT_OFFSET = 0x28
    IAT_OFFSET = 0x44
    DLL_NAME_OFFSET = 0x60
    HN_BASE = 0x70

    # IDT[0]: KERNEL32.dll
    struct.pack_into("<I", idata_sec, 0, IDATA_RVA + OFT_OFFSET)    # OriginalFirstThunk
    struct.pack_into("<I", idata_sec, 4, 0)                          # TimeDateStamp
    struct.pack_into("<I", idata_sec, 8, 0)                          # ForwarderChain
    struct.pack_into("<I", idata_sec, 12, IDATA_RVA + DLL_NAME_OFFSET)  # Name
    struct.pack_into("<I", idata_sec, 16, IDATA_RVA + IAT_OFFSET)   # FirstThunk (IAT)
    # IDT[1]: null terminator (20 bytes at offset 0x14, already zero)

    # DLL name
    idata_sec[DLL_NAME_OFFSET:DLL_NAME_OFFSET + 13] = b"KERNEL32.dll\x00"

    # Hint/Name table
    imports = [
        "VirtualProtect",
        "Sleep",
        "CreateThread",
        "FlushInstructionCache",
        "GetCurrentProcess",
        "DisableThreadLibraryCalls",
    ]

    hn_offsets = []
    hn_pos = HN_BASE
    for name in imports:
        hn_offsets.append(IDATA_RVA + hn_pos)
        struct.pack_into("<H", idata_sec, hn_pos, 0)  # hint = 0
        name_bytes = name.encode("ascii") + b"\x00"
        idata_sec[hn_pos + 2:hn_pos + 2 + len(name_bytes)] = name_bytes
        hn_pos += 2 + len(name_bytes)
        if hn_pos % 2:
            hn_pos += 1  # align to 2

    # OFT entries (point to hint/name)
    for idx, hn_rva in enumerate(hn_offsets):
        struct.pack_into("<I", idata_sec, OFT_OFFSET + idx * 4, hn_rva)
    # NULL terminator
    struct.pack_into("<I", idata_sec, OFT_OFFSET + len(imports) * 4, 0)

    # IAT entries (same as OFT before binding)
    for idx, hn_rva in enumerate(hn_offsets):
        struct.pack_into("<I", idata_sec, IAT_OFFSET + idx * 4, hn_rva)
    struct.pack_into("<I", idata_sec, IAT_OFFSET + len(imports) * 4, 0)

    # --- .reloc section ---
    reloc_sec = bytearray(RELOC_RAW_SIZE)

    # Build relocation entries for CODE section
    reloc_entries = []
    for r in sorted(relocs):
        reloc_entries.append(0x3000 | (r & 0xFFF))  # type HIGHLOW (3) | offset
    if len(reloc_entries) % 2 != 0:
        reloc_entries.append(0x0000)  # padding (type ABS)

    block_size = 8 + len(reloc_entries) * 2
    struct.pack_into("<I", reloc_sec, 0, CODE_RVA)      # PageRVA
    struct.pack_into("<I", reloc_sec, 4, block_size)    # BlockSize
    for idx, entry in enumerate(reloc_entries):
        struct.pack_into("<H", reloc_sec, 8 + idx * 2, entry)

    # --- PE Headers ---
    dos_header = bytearray(0x80)
    dos_header[0:2] = b"MZ"
    struct.pack_into("<I", dos_header, 0x3C, 0x80)  # e_lfanew

    pe_sig = b"PE\x00\x00"

    coff_header = bytearray(20)
    struct.pack_into("<H", coff_header, 0, 0x14C)    # Machine: i386
    struct.pack_into("<H", coff_header, 2, 4)        # NumberOfSections
    struct.pack_into("<I", coff_header, 4, 0x683B4A00)  # TimeDateStamp
    struct.pack_into("<H", coff_header, 16, 224)     # SizeOfOptionalHeader
    struct.pack_into("<H", coff_header, 18, 0x2102)  # DLL | EXECUTABLE_IMAGE | 32BIT_MACHINE

    opt_header = bytearray(224)
    struct.pack_into("<H", opt_header, 0, 0x10B)     # Magic: PE32
    opt_header[2] = 14                                # MajorLinkerVersion
    opt_header[3] = 0                                 # MinorLinkerVersion
    struct.pack_into("<I", opt_header, 4, CODE_RAW_SIZE)  # SizeOfCode
    struct.pack_into("<I", opt_header, 8, DATA_RAW_SIZE + IDATA_RAW_SIZE + RELOC_RAW_SIZE)
    struct.pack_into("<I", opt_header, 16, dllmain_rva)  # AddressOfEntryPoint
    struct.pack_into("<I", opt_header, 20, CODE_RVA)  # BaseOfCode
    struct.pack_into("<I", opt_header, 24, DATA_RVA)  # BaseOfData
    struct.pack_into("<I", opt_header, 28, IMAGE_BASE)
    struct.pack_into("<I", opt_header, 32, SECTION_ALIGN)
    struct.pack_into("<I", opt_header, 36, FILE_ALIGN)
    struct.pack_into("<H", opt_header, 40, 6)        # MajorOSVersion
    struct.pack_into("<H", opt_header, 42, 0)        # MinorOSVersion
    struct.pack_into("<H", opt_header, 48, 6)        # MajorSubsystemVersion
    struct.pack_into("<H", opt_header, 50, 0)        # MinorSubsystemVersion
    struct.pack_into("<I", opt_header, 56, SIZE_OF_IMAGE)
    struct.pack_into("<I", opt_header, 60, 0x400)    # SizeOfHeaders
    struct.pack_into("<H", opt_header, 68, 2)        # Subsystem: WINDOWS_GUI
    struct.pack_into("<H", opt_header, 70, 0x0040)   # DllCharacteristics: DYNAMIC_BASE
    struct.pack_into("<I", opt_header, 72, 0x100000) # SizeOfStackReserve
    struct.pack_into("<I", opt_header, 76, 0x1000)   # SizeOfStackCommit
    struct.pack_into("<I", opt_header, 80, 0x100000) # SizeOfHeapReserve
    struct.pack_into("<I", opt_header, 84, 0x1000)   # SizeOfHeapCommit
    struct.pack_into("<I", opt_header, 92, 16)       # NumberOfRvaAndSizes

    # Data directories
    # [1] Import: RVA=IDATA_RVA, Size=0x28 (one IDT entry + null)
    struct.pack_into("<I", opt_header, 96 + 1 * 8, IDATA_RVA)
    struct.pack_into("<I", opt_header, 96 + 1 * 8 + 4, 0x28)
    # [5] BaseReloc: RVA=RELOC_RVA, Size=block_size
    struct.pack_into("<I", opt_header, 96 + 5 * 8, RELOC_RVA)
    struct.pack_into("<I", opt_header, 96 + 5 * 8 + 4, block_size)
    # [12] IAT
    struct.pack_into("<I", opt_header, 96 + 12 * 8, IDATA_RVA + 0x44)
    struct.pack_into("<I", opt_header, 96 + 12 * 8 + 4, (len(imports) + 1) * 4)

    # Section headers
    sections = bytearray(4 * 40)

    # CODE
    sections[0:5] = b"CODE\x00"
    struct.pack_into("<I", sections, 8, SECTION_ALIGN)
    struct.pack_into("<I", sections, 12, CODE_RVA)
    struct.pack_into("<I", sections, 16, CODE_RAW_SIZE)
    struct.pack_into("<I", sections, 20, CODE_FILE)
    struct.pack_into("<I", sections, 36, 0x60000020)  # CODE|MEM_EXECUTE|MEM_READ

    # DATA
    sections[40:44] = b"DATA"
    struct.pack_into("<I", sections, 48, SECTION_ALIGN)
    struct.pack_into("<I", sections, 52, DATA_RVA)
    struct.pack_into("<I", sections, 56, DATA_RAW_SIZE)
    struct.pack_into("<I", sections, 60, DATA_FILE)
    struct.pack_into("<I", sections, 76, 0xC0000040)  # INIT_DATA|MEM_READ|MEM_WRITE

    # .idata
    sections[80:86] = b".idata"
    struct.pack_into("<I", sections, 88, SECTION_ALIGN)
    struct.pack_into("<I", sections, 92, IDATA_RVA)
    struct.pack_into("<I", sections, 96, IDATA_RAW_SIZE)
    struct.pack_into("<I", sections, 100, IDATA_FILE)
    struct.pack_into("<I", sections, 116, 0xC0000040)  # INIT_DATA|MEM_READ|MEM_WRITE

    # .reloc
    sections[120:126] = b".reloc"
    struct.pack_into("<I", sections, 128, SECTION_ALIGN)
    struct.pack_into("<I", sections, 132, RELOC_RVA)
    struct.pack_into("<I", sections, 136, RELOC_RAW_SIZE)
    struct.pack_into("<I", sections, 140, RELOC_FILE)
    struct.pack_into("<I", sections, 156, 0x42000040)  # INIT_DATA|MEM_DISCARDABLE|MEM_READ

    # Assemble headers
    headers = dos_header + pe_sig + coff_header + opt_header + sections
    assert len(headers) <= 0x400, f"Headers too large: {len(headers)}"
    headers += b"\x00" * (0x400 - len(headers))

    # Assemble final image
    image = bytearray(headers) + code + data_sec + idata_sec + reloc_sec
    # Pad to file size (accounts for any rounding)
    if len(image) < FILE_SIZE:
        image += b"\x00" * (FILE_SIZE - len(image))
    elif len(image) > FILE_SIZE:
        image = image[:FILE_SIZE]

    # Pad to nice aligned size for the final output
    final_size = 0x1400
    image += b"\x00" * (final_size - len(image))

    return image


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate dlc_enable.asi — DLC Content Activator for Mercenaries 2")
    parser.add_argument("--output", "-o", default="dlc_enable.asi",
                        help="Output path for the ASI plugin (default: dlc_enable.asi)")
    parser.add_argument("--verify", action="store_true",
                        help="Verify the generated PE structure")

    args = parser.parse_args()
    output_path = Path(args.output)

    print("Generating dlc_enable.asi...")
    print()

    asi_data = generate_dlc_enable_asi()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(asi_data)

    print(f"Generated: {output_path} ({len(asi_data):,} bytes)")
    print()
    print("This ASI plugin hooks the following Lua functions at runtime:")
    print("  - IsOnlineConnected() → always returns true")
    print("  - IsDLC()             → always returns true")
    print("  - IsMatchmakingInternet() → always returns true")
    print()
    print("Installation (alongside cruise.asi):")
    print("  1. Place dinput8.dll (ASI Loader Win32) in game directory")
    print("  2. Place cruise.asi in game/scripts/ (SecuROM bypass)")
    print("  3. Place dlc_enable.asi in game/scripts/ (DLC activation)")
    print("  4. Ensure scripts/global.ini has: DontLoadFromDllMain=0")
    print("  5. Ensure vz-patch.wad is in the game's data/ directory")
    print("  6. Run the game normally")
    print()
    print("How it works:")
    print("  The plugin waits 5 seconds for the game's Lua state to initialize,")
    print("  then scans the EXE's .rdata section for the Lua registration tables")
    print("  that define IsOnlineConnected, IsDLC, and IsMatchmakingInternet.")
    print("  It overwrites the C function pointers in those tables with a hook")
    print("  function that always pushes boolean true to the Lua stack.")
    print()
    print("  This makes the Extras menu believe EA servers are online and that")
    print("  DLC content is entitled for the current session.")
    print()
    print("NOTE: For DLC contracts to actually load, vz-patch.wad must contain")
    print("      PC-compatible DLC Lua scripts. Use 'make dlc-bootstrap' to")
    print("      inject the bootstrap scripts into the patch WAD.")

    if args.verify:
        print()
        print("=== PE Verification ===")
        # Basic PE checks
        assert asi_data[:2] == b"MZ", "Missing MZ header"
        pe_off = struct.unpack_from("<I", asi_data, 0x3C)[0]
        assert asi_data[pe_off:pe_off + 4] == b"PE\x00\x00", "Missing PE signature"
        machine = struct.unpack_from("<H", asi_data, pe_off + 4)[0]
        assert machine == 0x14C, f"Wrong machine type: {machine:#x}"
        num_sections = struct.unpack_from("<H", asi_data, pe_off + 6)[0]
        assert num_sections == 4, f"Wrong section count: {num_sections}"
        opt_magic = struct.unpack_from("<H", asi_data, pe_off + 24)[0]
        assert opt_magic == 0x10B, f"Wrong optional header magic: {opt_magic:#x}"
        chars = struct.unpack_from("<H", asi_data, pe_off + 22)[0]
        assert chars & 0x2000, "DLL flag not set in characteristics"
        print("  MZ header:       OK")
        print("  PE signature:    OK")
        print(f"  Machine:         i386 (0x{machine:04X})")
        print(f"  Sections:        {num_sections}")
        print(f"  Characteristics: 0x{chars:04X} (DLL)")
        print("  All checks passed!")


if __name__ == "__main__":
    main()
