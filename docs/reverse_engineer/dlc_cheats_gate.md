# Cheats-used gate: PS3 v1.03 → PC hook spec

Images: ps3-v103-na `EBOOT_patch103.elf` sha256 4d8370fc…5620; pc-v11 `genuine_patched_unpacked.exe` 819a96db…4b4c;
pc-v10 `mercs2_unpacked.exe` 8c179a99…c7ba; pc-v10-drmfree `mercs2_nodrm_v3.exe` 3a388d66…e564. All four
sha256s were checked against images.tsv in this run. Tools (read-only, python3 -I):
`scratchpad/cg/{elf,ppcdis,scan3,pe,pcdis,pcfind,pccallers,pcdisp,sig}.py`.
Grades: **P** = PROVEN (seen this run in disassembly or bytes), **I** = INFERRED, **S** = SPECULATIVE.

## 1. Persistence

**Where the flag lives**
- G = `*(u32*)0x012BF818`. **P**
  - The getter at 0x1c18e0 does `lwz r30,-0x7e38(r2)`; the TOC entry holds 0xfc2088. Then `lwz r11,-0x7964(r30)`; 0xfba724 holds 0x12bf818. Then `lwz r9,0(r11)` and `lbz r3,0x5e(r9)`.
  - r2 = 0x104efa0 is the TOC of 39,747 OPD descriptors.
- **G is not an options block.** It is the PS3 save manager: 16 slots, state machine FUN_001e78f0, slot summary table at G+0x3710 with a 0x90 stride. **P**
- The live save record sits at G+8: an 8-byte header followed by **R = G+0x10**, a 0x3458-byte blob. **P**
  - FUN_001e5ee8 writes R[0]=4 and R[4]=0x3458.
- **The flag is R+0x4E**, which is G+0x5E. **P**
  - The setter at 0x1c15e4 does `addi r9,G,8; stb r3,0x56(r9)`.

**How the PC `.profile` maps onto R**
- The PC `.profile` is `[CRC32][R]`: version 4 at file offset 4 and size 0x3458 at offset 8 (save_serialize_code_map §4). **P**
- So the flag would sit at PC file offset 0x52.
- The hero/upgrade/costume fields check out against this mapping (**P**):
  - PS3 G+0x59/0x5a/0x5b correspond to file offsets 0x4D/0x4E/0x4F;
  - PS3 cash at G+0x24 corresponds to PC singleton +0x2C.

**Reads and writes of G+0x5E** (scan3.py: per-function dataflow from G, including methods called with r3 = G+k)
- Exactly three direct accesses, at 0x1c15e4 (stb, setter), 0x1c18f4 (lbz, getter) and 0x1e5f74 (stb 0, record reset). **P** within the scanner's model.
- Blind spot: the scanner does not see accesses through slot buffers or the summary table.
  - The slot-list UI FUN_005c6108 reads summary +0/+4/+8/+0x10/+0x18/+0x39/+0x3c/+0x3d/+0x49 and never +0x3e, which is where the flag lands. So the save list never shows the flag. **P**
- The getter's 11 call sites are the complete list of consumers. There is no other reader of the byte. **P**
  - A raw scan of every PPC `b`/`bl` in text, including Ghidra gaps, finds exactly those 11 `bl 0x1c18e0` sites. The setter 0x1c15a8 has one caller, 0x554b6c (Pg.SetCheatsUsed).
- **FUN_001e5aa8 has 5 callers, not 4:** 0x50b4f0, 0x50da54, 0x5c6e58, 0x5c7a78, and **0x5ca520**, which sits in a Ghidra gap after FUN_005c91b0. **P** (same raw scan).

**Lua trigger and readers** (DLC01 script `docs/mercs2-dlc-luacd/src/dlc01/dlc01_mrxguipda.lua`, the decompiled v1.03/DLC PDA) **P** by text
- The host enters the cheat code `_tCheatEnable` and gets an "Enable cheats?" dialog. `_CheatsEnableCallback(1)` then sends NETEVENT_CHEATS_ENABLED and calls `Pg.SetCheatsUsed(true)`.
- Clients receive NETEVENT_CHEATS_ENABLED, see a "Cheats enabled by host" dialog, and call `Pg.SetCheatsUsed(true)`.
- `OnPlayerJoin` reads `Pg.WereCheatsUsed()` and re-broadcasts NETEVENT_CHEATS_ENABLED to the joiner.
- Every use is wrapped in `if Pg.WereCheatsUsed then`, so the script tolerates the bindings being absent, as they are on PC today.
- corpus_lua_xref returns 0 hits for both names. The Lua AST index does not cover the DLC tree, so the full v1.03 Lua set has not been searched (open question 7).

**The flag is per save game: it goes out with the save and comes back with the load**
- Save: state 15 of the save state machine (code at 0x1e7be0..0x1e7db8, inside Ghidra's truncated FUN_001e78f0) loads r27 = G through `*(r30-0x7f84) = 0x12bf818`.
  - It stamps the time with `std r3,0x28(r26)`, r26 = G+8, which lands at R+0x20 (PC file 0x24). Then it calls `bl 0x3fb388` with r8 = G+0x10 and r9 = 0x3458. **P**
  - 0x3fb388 forwards to FUN_003f8c58, the save-request queue in PgSysSaveGameManager. That the queue entry reaches cellSaveData is **I**.
- Load: FUN_001e60e0 checks each slot record for {4, 0x3458} and memcpys the newest one into G+8 (`memcpy(G+8, slot, 0x3460)`). **P**
  - So the byte on disk becomes the live flag.
- Reset: FUN_001e6048(G,…) calls FUN_001e5ee8(G+0x10), which stores the zero at 0x1e5f74. **P**
  - Callers:
    - PgSysSaveGameManager slot-4 init 0x3fb718: a one-shot boot reset. **P**
    - 0x5c69f0, which resets when byte S+0x30e9 == 0. S = *(0x1b6baf0). **P**
    - 0x5cc5b0 and 0x5cd4f0.
  - That these shell paths are New Game / no-storage starts is **I**. They are not named.
- Old saves: v1.00 FUN_001e2518 already zeroes R+0x4E with the same {4, 0x3458} header. **P**
  - So v1.03 reused an existing byte, the save format did not change, and v1.00 saves load with the flag clear.

**PC has the same byte, unused** (**P**)
- The PC record singleton sits at 0x1577a88 in v11 and 0x1578a88 in v10. Those values are read from the dump images at [0x1175054] and [0x1176054].
- R = singleton+0x18. FUN_00633df0 memsets 0x1577aa0 for 0x3458 bytes, then calls 0x634860 with eax = R.
- PC 0x634860 is the twin of FUN_001e5ee8. It zeroes R+0x4E at 0x63489d (`mov byte [edi+0x4e],bl`).
- File offset 0x52 is 0 in all 10 PC `.profile` fixtures: the 8 in mercs2_formats/fixtures/saves plus the 2 in game-files.

**PC copies the whole record in both directions**
- PC 0x636280 is the twin of FUN_001e60e0. **P**
  - It checks each slot for {4, 0x3458} at slot+8 and calls 0x634860 to reset a bad one.
  - At 0x6363eb..0x6363ff it does `memcpy(G+0x10, slot, 0x3460)`, then sets G+0x11 = 0.
  - PS3 does the same: `memcpy(G+8, slot, 0x3460)`, then G+8 = 0.
- The PC save write at 0x636003..0x636013 pushes `lea ecx,[edi+8]` (R) with size 0x3458 and the hero byte [edi+0x51]. This matches PS3 state 15. **P** for the arguments; that they reach the disk writer is **I**.
- So a byte at R+0x4E round-trips through the PC `.profile`. **P** on the load-newest path; **I** for a manual load of a named slot, which was not read.

**PC storage recommendation**: keep the flag at **PC singleton+0x66** (R+0x4E, file 0x52).
- Mark the record dirty with **singleton+0x11 = 1**. **I**: PS3 G+8 maps to PC +0x11, a +9 shift in the header against +8 in R. Three pieces of evidence:
  - FUN_00633df0 writes +0x11=1, +0x12=0, +0x13=1, +0x14..0x16=0. PS3 FUN_001e67c8 and FUN_001e6048 write the same pattern at G+8..0xd.
  - PC 0x6362d9 writes slot[1]=1, [2]=0, [3]=1. PS3 writes slot[0]=1, [1]=0, [2]=1.
  - PC load clears +0x11 where PS3 clears G+8.
- Nothing needs to change in the format or the CRC (CRC-32/BZIP2 over [4:] is recomputed on every write).
- Still to check live: that PC never writes +0x66 for some other purpose. No PC accessor scan for disp 0x66 was run.

## 2/3. Consumers PS3 → PC

Signatures: sig.py masks rel8/rel32 branch targets and any imm/disp ≥ 0x400000, then counts matches in every executable section.
- Every signature below matched **exactly one** location in each of the three PC builds.
- pc-v10 and pc-v10-drmfree always matched at the same VA. **P**

| # | PS3 v1.03 consumer (what the gate does) | PC twin and evidence | Hook VA v11 / v10 / v10-drmfree | Signature (start = VA) | Hook shape |
|---|---|---|---|---|---|
| 1 | 0xb9d10 PgSysNetAchievements slot 16, the AchievementAddCount handler: with cheats it skips posting script event 0x0fcce0ec (hash of "mrxachievements") | **0x6b4630**, not a Ghidra function. Same guards ([0x17bfbc8]==1 ≙ FUN_00010700()+8, [0x17bfdea] ≙ +0x22a), reads msg+0x80, posts 0xfcce0ec with name "AchievementAddCount". In the handler table at 0xbcec2c. **P** | 6b4630 / 6b4590 / 6b4590 | `51 83 3d ?? ?? ?? ?? 01 0f 85 ?? ?? ?? ?? 80 3d ?? ?? ?? ?? 00 0f 84 ?? ?? ?? ?? a1 ?? ?? ?? ??` | Detour the entry, before its `push ecx`. When cheats are set, `ret 4`; otherwise run the trampoline. A 5-byte jmp steals only `push ecx` + `cmp dword [abs],1` (8 bytes, position-independent), so nothing needs relocating |
| 2 | 0xba298 slot 15, the trophy unlock (looks the name up among 0x28 trophies): returns before the loop | **0x6b4610**: same guards, then `call 0x6b4320`, a SecuROM split-thunk `jmp [0x24d7b0c]`. Handler table 0xbcec24. Pairing **I** (guards plus table adjacency); what 0x6b4320 does on PC is not read | 6b4610 / 6b4570 / 6b4570 | `83 3d ?? ?? ?? ?? 01 75 ?? 80 3d ?? ?? ?? ?? 00 74 ?? e8 ?? ?? ?? ?? c2 04 00` | Detour the entry: `ret 4` when cheats are set |
| 3 | 0x5372b4 Net.GrantAchievement: no-op | **0x5c91e0** (luareg; translate direct 3001/3001). Enqueues message 0x32 {name} to the net queue 0x4bdf30. That queue is the PC copy of PS3's inline 256×0xd0 ring, not a backend. **P** | 5c91e0 / 5c9170 / 5c9170 | `55 8b ec 83 e4 f8 81 ec dc 00 00 00 8b 45 08 57 8d 4c 24 08 89 44 24 0c` | Detour the entry: when cheats are set, `xor eax,eax; ret` (cdecl lua_CFunction) |
| 4 | 0x550be4 Pg.AchievementAddCount: skips FUN_001e86a0 (the counter at G+0x34c8+i·4, which grants message 0x29 at the threshold) and still pushes false | **0x5d8400** (luareg). The FUN_001e86a0 twin is `call 0x634d70` at **0x5d84a2** (`push ebp; push eax; edx=G`), and 0x634d70 is a split-thunk `jmp [0x24d747c]`. **P** | gate block 5d8489 / 5d8499 / 5d8499 (call at +0x19) | `8b 44 24 10 85 c0 74 ?? 8b 4c 24 14 83 f9 ff 7e ?? 8b 15 ?? ?? ?? ?? 55 50` | Patch the branch: redirect the `je` at +6 to 0x5d84a7 when cheats are set. Or re-point the call at 0x5d84a2 to a stub that drops its two pushed args when cheats are set. Do not detour the thunk 0x634d70 |
| 5 | 0x537e0c Net.LeaderboardPushScore: no-op | **None**: there is no native PC binding, and the ASI implements it | n/a | n/a | Put the gate in the ASI's own LeaderboardPushScore |
| 6a | FUN_001e5aa8 = `G+0x4023 && G+0x4021 && !cheats` ("autosave allowed"; G+0x4021 = option 0x859543ea != 3). Polarity: `((c&0xff)-1)>>63` → 1 iff c==0. **P** (0x1e5b00..b04) | **0x5a1570**: `G+0xa86b && G+0xa869`, eax = G, with no cheats term. Option 0x859543ea writes `G+0xa869 = (v != 3)` at 0x634b86. **P**. PC has 3 callers, and each one pairs with a gated PS3 caller:
- 0x615a5b ↔ PS3 **0x5ca520**. **P** by identical shape: `r31/esi ==0 / ==2 → skip; ==1 → CanAutosave(G); if true goto …`.
- 0x6168ca, in FUN_00616830 (which holds dialog hash 0x716f2d21) ↔ PS3 0x5c6c38. **I**
- 0x616c8b (`sete` negation) ↔ PS3 0x5c7078, the shell variable. **I**

So a whole-function detour matches PS3 and adds no extra gate. | 5a1570 / 5a1580 / 5a1580 | `80 b8 6b a8 00 00 00 74 ?? 80 b8 69 a8 00 00 00 74 ?? b8 01 00 00 00 c3` | Detour the entry (24 bytes, no relative branches outside it): return 0 when cheats are set, else run the original |
| 6b | 0x50b2b0 save request, which calls aa8 and, when it is false, returns 1 **without saving** | **0x5a4040** ("retry" string plus 0x18000 buffers, the same shape as 0x50b2b0, **P**). The check is **inlined** at 0x5a41b5 | 5a41a7 / 5a41b7 / 5a41b7 | `80 3d ?? ?? ?? ?? 00 74 ?? a1 ?? ?? ?? ?? 80 b8 6b a8 00 00 00 74 ?? 80 b8 69 a8 00 00 00 74 ??` | Patch the branch: overwrite the 18 bytes at +0xe (0x5a41b5..0x5a41c6) with `call CanAutosaveStub; test al,al; je 0x5a422a; nop×5` |
| 6c | 0x50d6a8 script-host update (posts an extra event when aa8 is true) | **0x5a1880** inline at 0x5a1932, which posts an event through 0x5a0cb0 when allowed. Pairing **I** | 5a192d / 5a193d / 5a193d | `a1 ?? ?? ?? ?? 38 98 6b a8 00 00 74 ?? 38 98 69 a8 00 00 74 ??` | Patch the branch: overwrite the 16 bytes 0x5a1932..0x5a1941 (they compare against `bl`, which is 0 there) with `call stub(5) + test al,al(2) + je 0x5a195e rel32(6) + nop×3` |
| 6d | (no PS3 counterpart identified) | Two more inline copies, at 0x4bb531 (gap after FUN_004bb27a; it clears G+0x11 and G+0xa867 when not allowed) and 0x5a464e (+0xa869 only, FUN_005a4510). The FUN_005a4510 site is the SaveData handler region | 4bb52c / 4bb43c / 4bb43c | `a1 ?? ?? ?? ?? 38 88 6b a8 00 00 74 ?? 38 88 69 a8 00 00 75 ?? 88 48 11` | Open: no PS3 gate is proven here, so leave it unhooked until it is paired |
| 7 | 0x1e9afc save flow FUN_001e9888 (slot == -1, autosave): `bit = S+0x30e9; if online { if (G+0x4023&&G+0x4021) {if cheats bit=0} else bit=0 }` | **SecuROM-moved** body at .securom **0x24fc280** (eax = slot, ecx = edi = G). `cl = [[0xed465c]+0x3fe05]`; if [0xdfad77] { al = (G+0xa86b && G+0xa869) ? [0x24de04c] : 0; cl &= al }. Then +0xa86c/+0xc3 match PS3 +0x4024/+0xbb. **P** | site 24fc293 / 2470983 / 2470983 (the `mov eax,[imm]` at +0x26) | `80 3d ?? ?? ?? ?? 00 a1 ?? ?? ?? ?? 8a 88 05 fe 03 00 74 ?? 80 bf 6b a8 00 00 00 74 ?? 80 bf 69 a8 00 00 00 74 ?? a1 ?? ?? ?? ??` | Patch the branch inside the moved code: replace the 5-byte `mov eax,[imm32]` at +0x26 with `call stub` (stub returns eax = cheats ? 0 : original dword). The stub must preserve **ecx**, since the next instruction is `and cl,al`, and **edi** (= G). Patch in memory only; it sits in .securom |
| 8 | 0x1e9b2c FUN_001e9888 → FUN_001e9028 money milestones: ACHIEVEMENT_MILLIONAIRE (≥1e6) and ACHIEVEMENT_BILLIONAIRE (≥1e9), UpdateLeaderboard "Cash", messages | **0x636740**: same thresholds (0xf4240, 0x3b9aca00), same G+0x3594 high-water mark, strings at 0xbbd0e8/0xbbd100/0xbbd118. Not a Ghidra function. Its only caller is the .securom save flow 0x24fc3c9 (`push ret; jmp 0x636740`). There it runs **unconditionally**, after message 0x3b {G+0xb5} (PC id for PS3's 0x32 {G+0xad}) | 636740 / 636870 / 636870 | `81 ec 58 01 00 00 53 33 db 38 1d ?? ?? ?? ?? 55 56` | Detour the entry: plain `ret` when cheats are set (edi = G, no stack args, ends in `ret`) |
| 9 | 0xf21e4 PgSysNetOnline slot 15, session create: the flag is the 11th argument to FUN_00684508 | **0x6c9a60** (hash pair 0x9631e560/0x9a4bcede + "hostingDialog"; copies 0x33 dwords; fields 0xda34..0xda48) **P**. Its create call FUN_00841600 has **no** cheats argument | n/a | n/a | No slot exists in the PC call. A matchmaking attribute would have to be added on the FESL/Theater side. What PS3 FUN_0088f0f0 does with the argument is open |
| 10 | 0xed6fc PgSysNetOnline slot 39, session update: flag is the last argument of FUN_00684478 | PC block at 0x6cad88..0x6cae15 (Ghidra attributes it to FUN_006caa30) re-reads 0xda34..0xda48 and calls 0x841650 with 9 args and no cheats argument. **P** for the arg list; pairing **I** | n/a | n/a | Same as #9 |
| 11 | 0x550b6c Pg.WereCheatsUsed / Pg.SetCheatsUsed | **Absent** on PC (there are no such luareg names) | n/a | n/a | Bindings in the Blow It Up Again ASI (`shipments/blow-it-up-again/client`) that read and write singleton+0x66 (singleton = [0x1175054] in v11, [0x1176054] in v10). The setter also sets the dirty byte singleton+0x11 = 1 (**I**, see §1) and queues PC message 0x3b {singleton+0xb5}, mirroring PS3's 0x32 {G+0xad}. DLC01 PDA Lua calls them (§1) |

**What PC lacks entirely**
- Any platform achievement or trophy backend. **P**: no "xlive"/"XLIVE" bytes anywhere in pc-v11, and no RTTI for PgSysNet* (PC RTTI has none of those classes).
  - PC still tracks achievements: the net-message queue 0x4bdf30, handlers 0x6b4610/0x6b4630, and the MrxAchievements Lua event.
- Native LeaderboardPushScore.
- The cheats argument in session create and update.
- Set/WereCheatsUsed.
- PS3's setter also queues message 0x32 {G+0xad}. On PC that is 0x3b {G+0xb5}; the id offset +9 matches GrantAchievement 0x29→0x32. **P** for both ids.

## Open questions and next steps
1. Make sure PC never uses singleton+0x66 for anything else. Run pcdisp.py for disp 0x66 against regs loaded from [0x1175054], and for 0x4e off R, over .text and .securom. Then confirm live in x32dbg with a read-only watch the user arms.
2. What 0x6b4320 (split-thunk → .securom) does on PC for message 0x32. Follow [0x24d7b0c].
3. Pair the PC-only inline copies 0x4bb531 and 0x5a464e with their PS3 twins: 0x4bb27a region, and PS3 0x50af28, the other FUN_001e9888 caller.
4. Name the PS3 FUN_001e6048 shell callers 0x5cc5b0 and 0x5cd4f0 (new game?) from their string and event hashes.
5. PS3 FUN_0088f0f0: find where the cheats argument lands in the NP session attributes. That decides whether the PC FESL/Theater side needs an attribute.
6. The PS3 save-queue register mapping into FUN_003f8c58 (Ghidra's parameter list disagrees with the registers at the call).
7. Search the full v1.03 Lua set for other Set/WereCheatsUsed callers: the PKG USRDIR WADs under game-files/ps3-version, using unluac. Only the DLC01 PDA script has been seen so far.
8. The PC manual-load path for a named slot: confirm it also copies the whole 0x3460-byte record.
