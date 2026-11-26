# Seat TYPE string -> seat (Vehicle.GetSeatByType, Vehicle.Enter)

Sources read this run: Ghidra exports `x360-retail.functions.jsonl` and `pc-v10.functions.jsonl` (decomp only), `x360-retail.annotate.jsonl`, the PC image `mercs2_unpacked.exe` via radare2 (byte level), and the vendored Lua 5.1 header `tools/wad_simulator/crates/mercs2_luac/vendor/lua.h`. No x360 binary path was in the brief and the Ghidra bridge is off-limits, so **no x360 instruction-level check was done**; x360 claims rest on the decompile. Grades: PROVEN = read this run; INFERRED = reasoned, unchecked; SPECULATIVE = guess.

## Counterpart addresses

| Function | x360-retail | pc-v10 | Basis |
|---|---|---|---|
| Vehicle.GetSeatByType | 0x823469a8 | 0x005e72d0 | annotate translation; PC disasm shows the same switch (PROVEN) |
| Vehicle.Enter (type-string form) | 0x82347558 | 0x005e8060 | annotate translation (tool) |
| Vehicle.EnterBySeatGuid | 0x82347748 | 0x005e8250 | annotate (not read) |
| Vehicle.GetSeatParams | 0x82346af8 (ghidra user label "IsDriver", not evidence) | 0x005e7470 | annotate; PC decomp read (PROVEN) |
| Vehicle.GetSeatFromRider | 0x823468c8 | none | not read |

x360 type helpers: 'c' FUN_8229d0c0, 'd' FUN_8229c800, 'g' FUN_8229cf68, 'p' FUN_8229d218. Their PC call targets are thunks (section 2 note).

## 1. Interpreting the type string

- **PROVEN (x360 decomp + PC disasm):** the 2nd argument is read as a Lua string, and only its **first character** is used. The char is case-folded: x360 `FUN_8285fbd0` maps A-Z to a-z (size 20). PC calls MSVCR80 `tolower` (PC 0x005e7396).
- **PROVEN:** the folded char is switched on (`c-99`). There are no string compares and no hash.
- **PROVEN mapping (x360 case label = char-99):** `'c'`->FUN_8229d0c0, `'d'`->FUN_8229c800, `'g'`->FUN_8229cf68, `'p'`->FUN_8229d218. Any other char returns 0 (section 5). So "driver", "gunner", "passenger", "cargo" also work, because only the first char is read.
- **PROVEN (PC byte level):** table at PC 0x005e7460, index = char-99, 14 bytes `00 01 04 04 02 04 04 04 04 04 04 04 04 03`. So c->0, d->1, g->2, p->3, others->4 (default). `cmp eax,0xd / ja default`, then `jmp [edx*4+0x5e744c]`. Jump table entries 0x5e73d5 (c), 0x5e73b5 (d), 0x5e73c5 (g), 0x5e73e5 (p), default 0x5e73fa. Each calls a thunk: c->0x536a90, d->0x5361a0, g->0x536950, p->0x536bd0.
- **PROVEN:** missing or empty string -> the default char is `'d'`. PC 0x005e736f stores 0xbb23e8, which holds bytes `64 00 00 00` ("d"). The x360 analogue `DAT_820d8c9c` was not read; INFERRED to be the same.

## 2. Seat matching and the flag bits

Each helper takes (vehicle handle, bool) and walks the vehicle's seats:

1. `FUN_82861bd4` (x360) is a no-op (`return;`, size 4). Ghidra hides that the vehicle handle passes through in r3, so the key is the vehicle handle. INFERRED from the no-op and the PC body, which uses the first argument directly.
2. `FUN_823dab38(iter, container 0x83653df8, vehicle, 0, 1)` opens the vehicle's seat list. `FUN_823dac60` advances it. Each element is a seat GUID.
3. For seat GUID `g`, the flags word is the first word of record `*FUN_823db8f0(0x83653e8c, g)`. If `DAT_83653e7c` bit 3 is clear, the code takes a `FUN_823daf68` path with a `FUN_823f7b88` fallback (not characterised).
4. **x360 masks (PROVEN as decompiled):**
   - 'c' FUN_8229d0c0: `w & 0x20000000`
   - 'd' FUN_8229c800: `w & 0x80000000`
   - 'g' FUN_8229cf68: `w & 0x40000000`
   - 'p' FUN_8229d218: `(w & 0xE0000000) == 0`
   - `FUN_8229d688` (size 216) classifies the same bits the same way: 31->4 ('d'), 30->2 ('g'), none of 31/30/29 -> 1 ('p'), 29 only -> 0 ('c').
5. **PC bit meaning (PROVEN, PC decomp of GetSeatParams FUN_005e7470, not virtualised):** IsDriver = `w & 0x1`, IsGunner = `>>1 & 1`, IsCargo = `>>2 & 1`, IsHijackable = `>>5`, IsHijackBlocker = `>>6`, IsRiderInvisible = `>>7`, IsRiderVulnerable = `>>8`, IsRiderBashable = (bit 9, value arg not shown), IsStowable = `>>10`, StowSeatGuid = word 1. Bit 9 (0x200) also gates a call to FUN_0059dbe0. Labels come from the string names Ghidra attached.
6. **Encoding mirror (INFERRED, strongly supported):** the x360 word stores the PC bit n at x360 bit 31-n. The 9-field decode order is identical on both sides under that mirror (x360 26/25/24/23/22/21 vs PC 5/6/7/8/9/10, word 1 = StowSeatGuid). The x360 `FUN_8229cd70` tests bit 19 (`>>0x13`), which is PC bit 12, the "player usable" bit from the brief. So the mapping for the type bits is:

   | Type | x360 mask (table word) | PC mask (SeatParameters word0) | PC field |
   |---|---|---|---|
   | 'd' | 0x80000000 | 0x00000001 | IsDriver |
   | 'g' | 0x40000000 | 0x00000002 | IsGunner |
   | 'c' | 0x20000000 | 0x00000004 | IsCargo |
   | 'p' | none of the above | none of 0x7 | - |

   The brief's SeatParameters word0 values are in PC order: the driver's 0x1021 has bit 0 (IsDriver) and bit 12 (usable); the boarding 0x1004 has bit 2 (IsCargo) and bit 12; front_left 0x120 has none of bits 0-2 (a passenger). Because this word is in PC order, the x360 table word is the bit-mirrored form. I did **not** find the code that builds it, so this is INFERRED.
7. **Static limit:** the PC helper bodies are not readable. `thunk_FUN_028ed000` (0x5361a0) is `jmp [0x245e2f0]`, which lands in FUN_028ed000 = `FUN_006499f0(&PTR_PTR_00df8188,0,1)`, a VM dispatch. The 'g' and 'p' slots point at non-code stubs in the 0x02xxxxxx region. Their mask constants can only be read live (x32dbg) and were not read. The PC body at 0x028ed000 reads `test bl,bl`, `[ecx+0x14]`, `[ecx+0x60]`, and calls 0x536640 on the true path, the same structure as the x360 'd' helper.

## 3. Third (bool) argument

- **PROVEN (control flow):** `false` tests only the type bit. `true` skips a seat if `FUN_823da330(0x836540fc, seat) != 0` or `FUN_8229cbb8(seat) != 0`. Otherwise it runs the type test.
- **PROVEN:** `FUN_8229cbb8(seat)` finds the seat's vehicle via `FUN_82156978(0x83653df8, seat)`, walks that vehicle's seats S, and returns 1 if a record in `0x836540fc` keyed by some S has `+8 == seat`.
- **INFERRED meaning:** `true` = "only unoccupied seats". The schema of `0x836540fc` (rider/occupant records) is not established.
- `Vehicle.Enter` passes literal `false` (section 6).

## 4. Several matches

- **PROVEN:** the helper returns on the first passing seat.
- **NOT DETERMINED:** that seat's position in iteration order (container 0x83653df8 primary index, walked by FUN_823dac60). I did not show it is SeatLink record order; the build path of 0x83653df8 was not read.
- Practical effect (INFERRED): for 'd' on the boat, only the driver seat carries the bit, so order does not matter. For 'c', both Boarding seats match, so order decides.

## 5. No match, and what is pushed

- **PROVEN (x360 decomp):** result 0 or no char match -> `FUN_82205030(L, 0)` -> `FUN_827df798(L)`, which writes 0 at +4 and advances the stack by 8. Tag 0 = nil. A found seat -> `FUN_827dfaf8(L, guid)`, which writes the guid at +0 and tag **2** at +4, then advances by 8. No vehicle argument -> `FUN_82206f20` -> nil.
- **PROVEN (PC byte level, Vehicle.GetSeatByType 0x005e72d0):** stack check `call 0x85d5d0` at 0x5e7402. Failure -> `xor eax,eax` at 0x5e732e (returns 0). Result 0 -> nil path at 0x5e7412 (tag 0 at +4, `add [ebx+8],8`, `mov eax,1`). Nonzero -> 0x5e7430 writes the guid at +0 and tag 2 at +4, advances by 8, `mov eax,1`. Both success paths return 1.
- **PROVEN (vendored `lua.h`):** `LUA_TNIL 0`, `LUA_TLIGHTUSERDATA 2`, `LUA_TNUMBER 3`. So **a found seat is pushed to Lua as a light userdata, not a number**. Return count is 1.

## 6. Vehicle.Enter (x360 0x82347558, PC 0x005e8060)

- **PROVEN (x360 decomp):** the same char switch and the same four helpers, each called with literal `0` (no occupancy filter).
- Args: 1 vehicle handle, 2 character handle, 3 type string, 4 bool `bImmediate` (default 1), 5 bool (default 0).
- Found and `bImmediate`: `FUN_822a03f8(character, seat, 0, arg5)`, then `FUN_8220d528`. Found and not `bImmediate`: `FUN_8229c358(character, seat, 0)`; if nonzero, `FUN_8229f440(character)` and `FUN_8220d528`. Otherwise falls to nil.
- Default (missing type) and no-match behave as in section 1 and section 5. The `default:` case in the Enter switch jumps to the nil path.

## NOT DETERMINED

1. **Writer of the x360 seat word at 0x83653e8c** (which code sets it and whether it is a bit-mirror of SeatParameters word0). Insert-or-get call sites are in `map_83653e8c.txt` in this folder. Read and rejected: `FUN_82185408` (reads bit 31, writes nothing) and `FUN_8229a648` (reads only).
2. **Iteration order of container 0x83653df8** (SeatLink order or not).
3. **Schema of container 0x836540fc** and the exact meaning of "occupied".
4. **Fallback path** `FUN_823f7b88` and `DAT_83653e7c` bit 3.
5. **x360 instruction-level confirmation** (switch, masks, return count, the default-string address `DAT_820d8c9c`). Not available: no x360 binary path in the brief, and the Ghidra bridge is off-limits.
6. **PC mask constants in the type helpers.** VM-dispatched (section 2, item 7). The GetSeatParams masks in section 2 item 5 are PC-proven and cover the same bits.
7. **x360 label strings** of the GetSeatParams fields (the mirror mapping in item 6 is inferred from field position, not from the x360 strings).
8. **Where bit 12 is used** beyond FUN_8229cd70's bit-19 read on x360. The 'd'/'g'/'c'/'p' paths do not test it.
