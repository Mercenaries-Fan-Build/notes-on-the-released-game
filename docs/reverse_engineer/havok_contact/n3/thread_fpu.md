# Which thread runs FUN_008FD040 / FUN_008FDA80, and its x87 FCW (pc-v10)

Exe: `game-files/canonical/dumps/mercs2_unpacked.exe` (pc-v10). Capture:
`game-files/memory-dumps/updated-chris-exports/20261103_new-game-first-mission-start.dmp`.
All scripts/outputs are in this folder.

## Answer

- **Thread: the Pimp cpu-0 thread = the WinMain/main-loop thread = captured tid 15824, and only that thread.** PROVEN
  (code + capture; one small hole in §3).
- **FCW on it: 0x027F (PC = 53-bit double, RC = nearest, all exceptions masked).** PROVEN at capture time
  (thread parked in ntdll). No game `.text` code changes PC on that path. Non-`.text` code (DLLs, SecuROM) during the step: NOT DETERMINED (§5).
- The 24-bit thread tid 11456 (FCW 0x007F) is the **Pimp worker, cpu index 1** (`FUN_00876400`). PROVEN
  (TLS cpu index). It does **not** run the Havok step (§3). That it is the D3D device thread is INFERRED.

## 1. Call chain into the two targets (Ghidra export callers + disassembly; PROVEN)

`FUN_00631670` (WinMain body; writes TLS cpu index 0 at decomp line `*(TLS+8) = 0`) loops
`while (!DAT_01175fff) { FUN_00630ef0(); push pump job; FUN_008765c0(wait) }`
→ `FUN_00630ef0` (sole caller 0x631938) → `FUN_004c14f0` (0x630fac/0x630fc2) → `FUN_004c15e0` (0x4c153b)
→ virtual call `[vptr+0xC]` on the current game-state object (0x4c1633/0x4c1667/0x4c16b6)
→ `FUN_004c09c0` (vtable 0xBB0460 slot 3 = 0xBB046C; vtable referenced by the static object at 0xD6C244)
→ state 2 → `FUN_004c0ec0` (0x4c0b6a) → `FUN_004c9740` (0x4c0ed6) → `FUN_004036f0` (0x4c988f, physics substep loop, 1..3 substeps)
→ `FUN_008d61a0` (call 0x403960, ecx = [world+0x23c]) → `FUN_008f6ea0` (0x8d61a3, "TtSimulate" scope)
→ `FUN_008f6c10` (0x8f6ef1, Havok job loop: switch on job type)
   - case 0 → `FUN_009001b0` (0x8f6cac) → **`FUN_008fd040`** (0x90041d)
   - case 0xD/0xF → **`FUN_008fda80`** (0x8f6da5)

Live capture check (PROVEN): state list `0x17BBCCC` = {0xD6C22C, 0x14538B8, 0x149FDA0, 0xD6C238, 0xD6C244},
count `[0x17BBCF4]`=5, current `[0x17BBCF8]`=4, `[0x17BBCFC]`=4 → current object 0xD6C244, vptr 0xBB0460,
state `+8` = 2 → the branch that calls `FUN_004c0ec0`. (`mercs2_probe dump-read <dmp> 0x17bbcc8 72`, `… 0xd6c244 16`; `statelist.txt`.)

Other callers of the targets: `FUN_008fd040` also from `FUN_008f2970` ← `FUN_008f2e90` (no direct callers;
pointer at 0xB59C64/0xB59E14/0xB5A8B4 = Havok vtables). `FUN_008f6c10` also from `FUN_008f6f60` (vtable 0xB59E48).
`FUN_008f6ea0` also from `FUN_008f80a0` (vtable 0xB59E10). These are virtual entries of the same Havok
simulation object; not tied to a thread by code here (see §3 for the TLS proof that covers them).

## 2. Pimp threads and queues (PROVEN)

- Worker `FUN_00876400(cpu)` writes `TLS[_tls_index]+8 = cpu`; spawned once at 0x876834 `CreateThread` (IAT 0xB051C0) with lpParameter 1 (0x876821).
- Only two writers of TLS+8 in the whole decomp: `FUN_00631670` (=0) and `FUN_00876400` (=param) (`g_tls8.txt`). TLS template +8 = 0xFFFFFFFF (`.tls` 0x19FB000; `tlstpl.txt`).
- Capture: tid 15824 cpu index 0, tid 11456 cpu index 1, all 26 others -1 (`thr.py` → `thr.txt`, via TEB+0x2C → slot `_tls_index`=0 → +8).
- Queue routing `FUN_0084af70`: cpu0 high = 0xFF4650, cpu0 low = 0xFF4618, cpu1 high = 0 (`[0x19F9170]`), cpu1 low = 0xFF45E8 (`[0x19F9174]`). Worker and the waiting-drain `FUN_008765cf` both index rings by their own TLS cpu index.
- `FUN_004036f0` also posts job type `DAT_00d2d9c4` (registered in `FUN_00402e90` → handler `FUN_004036b0`, which itself calls `FUN_008d61a0` if `[world+0x23ac]==0`) into ring 0xFF4650 (EnterCS 0xFF4668 at 0x40380b) = cpu0's high ring → drained only by cpu 0. Whichever of the inline call (0x403960) or this job gets there first runs the step; both are on cpu 0.
- The window (`LAB_00631430`: RegisterClass + `CreateWindowExA` IAT 0xB054DC at 0x6315b6) and the message pump (`FUN_006315f0`) are posted by WinMain to ring 0xFF45E8 → run on the cpu-1 worker.

Live values in the capture (`live.py` → `live.txt`, PROVEN): `[0x19F9044]`=0xFF4650, `[0x19F9048]`=0xFF4618,
`[0x19F9170]`=0, `[0x19F9174]`=0xFF45E8 (routing unchanged at runtime); `[0xD2D9C4]` = **6** → handler slot 6 =
`FUN_004036b0` for both CPUs (`htab0.txt`/`htab1.txt`: `0x19F904C+6*8` and `0x19F9178+6*8`).

**"Ring job type 6 (Havok)" = `FUN_004036b0`.** `DAT_00d2d9c4` is read at exactly one place in either exe
(raw byte search `c4 d9 d2 00`, unpacked + n2patched2: 0x402f0c write in `FUN_00402e90`, 0x4037ce read in
`FUN_004036f0`; `rawrefs.txt`), and that poster writes it into ring 0xFF4650 only. So type 6 is executed by the cpu-0
waiting drain `FUN_008765cf` (same dispatch code as the worker `FUN_00876400`), never by the worker. The claim that the
worker `FUN_00876400` handles type 6 is false for this build (the handler is registered for cpu 1 too, but nothing posts it to cpu 1's ring).

Posters to the cpu-1 ring (CS 0xFF4600 / buffer 0xFF45F4 / base 0xFF45E8, raw refs): `FUN_00498150`, `FUN_004c00e0`,
`FUN_00631670`, `FUN_0046a920`. None of them reads `DAT_00d2d9c4`.

All direct references to the step entries, raw rel32 + pointer search in both exes (`relcall2.txt`, `relcall3.txt`):
`8d61a0` ← 0x4036d9 (`FUN_004036b0`), 0x403960 (`FUN_004036f0`); `8f6ea0` ← 0x8d61a3, 0x8f80e7; `8f6c10` ← 0x8f6ef1, 0x8f7022;
`9001b0` ← 0x8f6cac; `8fd040` ← 0x8f2c80, 0x90041d; `8fda80` ← 0x8f6da5; `4036f0` ← 0x4c988f; `4036b0` only as data
(0x402ee6 registration, the two handler slots); `8f80a0`/`8f6f60`/`8f2e90` only as vtable entries (0xB59E10, 0xB59E48;
0xB59C64/0xB59E14/0xB5A8B4). The job queue fetch `FUN_00a083e0` has one caller (`FUN_008f6c10`).

## 3. Capture TLS evidence (PROVEN)

`FUN_008f6ea0` / `FUN_008f2e90` dereference `TlsGetValue(DAT_00dfe754)+4/+0xC` and `FUN_008f6c10` dereferences
`TlsGetValue(DAT_00dfe750)+0x88` with no null check. In the capture `TLS[25]` (= `DAT_00dfe754`) is non-NULL only on
tid 15824 (`n2/tlsscan.txt`), NULL on tid 11456. `TLS[24]` (= `DAT_00dfe750`) is 0x2005E800 on tid 15824 and NULL on
all 27 others (`live.txt`).

This covers the virtual entries too (`8f2e90` and `8f6ea0` deref TLS[25] unconditionally at entry; `8f6c10` derefs
TLS[24]+0x88 as soon as it gets a job, before dispatching to `9001b0`/`8fda80`). It is an exclusion, not just
consistency, because the slots are never cleared:
- `TlsSetValue` (IAT 0xB051BC) has exactly two call sites in either exe (raw search: 0x88cd7f in `FUN_0088cd50`,
  0x88deb5 in `FUN_0088de80`; `tlsset.txt`).
- Attach `FUN_00891080` ← `FUN_004132a0` (← jobtype-0 handler 0x4c0eb0 `jmp`, and `FUN_004c95d0` 0x4c9723) and
  ← `FUN_00891230` ← `FUN_00413310` ← `FUN_00402e90` (physics init).
- The jobtype-0 attach job (`[0xD28B9C]` = 0 live; read only at 0x4c95f5 and in the 0x328xxxx registration code) is posted
  by `FUN_004c95d0` into ring 0xFF4650 (cpu 0) only.
- The only clearing path, `FUN_008910b0` (`FUN_0088cd50(0)`), is called only by `FUN_00891440`, which has no call or
  pointer reference in either exe.
So the worker's Havok TLS has never been set in this session; had it executed any of these entries it would have
dereferenced NULL. Remaining hole: a `TlsSetValue` reached through `GetProcAddress` or the SecuROM IAT copy
(0x23F1639, one reference at 0x1c8b7fb in SecuROM code) was not excluded.

## 4. Every FCW-changing site checked

- `.text` full disassembly (`text_full.txt`, `fpu_sites.txt`): 471 `fldcw`, 235 `fnstcw`, **0 `fninit`/`finit`**, 0 `ldmxcsr`.
  Every well-formed `fldcw` is the MSVC truncation idiom `fnstcw m; movzx eax,m; or eax,0xC00; fldcw tmp; fist(p); fldcw m`
  — changes RC only, restores; PC untouched (`fldcwctx.txt`, `fldcw2.txt`). The rest (`[ebx+4*eax]`, `[edx+eax-0x53ccd744]`, …,
  and the `frstor`/`fldenv` hits) are mis-decoded SecuROM-garbled bytes (e.g. 0x6218f2 is jumped over by `jmp 0x6218fe` at 0x6218f0).
- No `fldcw` site lies in the direct-call closure of `FUN_008f6c10` (186 fns), `FUN_004036f0` (255) or `FUN_008f2e90` (96) (`fpucls.py`).
  Havok-range sites (`FUN_008df590`, `FUN_008fc4c0`, `FUN_00981950`) are the RC-truncation idiom.
- `_controlfp_s` (IAT 0xB0546C, stub 0x9EEBAE): only caller `FUN_007c9410` (Scaleform/GFx, vtable 0xBDF238):
  0x7c9462 read, 0x7c9475 set `_PC_64` (new 0, mask 0x30000), restored at 0x7c95fc / 0x7ca26b. Not on the Havok path.
  `__control87` copies exist only in SecuROM sections (0x1C8FEEA, 0x222ABA1, 0x22D3333, 0x233A8CA, 0x236D733); no `.text` caller found.
- D3D: `Direct3DCreate9(0x20)` in `FUN_0074c590`; `IDirect3D9::CreateDevice` at 0x754f30 in `FUN_00754e90` with
  BehaviorFlags = `[esi+4]&0x10 ? 0x24 : 0x44` (0x754eba–0x754ec6) → SOFTWARE_VP|MULTITHREADED or HARDWARE_VP|MULTITHREADED;
  **D3DCREATE_FPU_PRESERVE (0x2) never set** (flag values: recall, INFERRED). The CreateDevice caller chain
  (`FUN_0074cec0` ← `FUN_0074c7ac` ← SecuROM split entry 0x4ddaf1, pointer at 0x24558A0) was not resolved to a thread.

## 5. Grades and gaps

- tid 15824 = cpu 0 = thread that runs `FUN_004036f0` → `FUN_008fd040`/`FUN_008fda80` (inline, and the type-6 job on its own ring): PROVEN.
- Exclusively that thread: PROVEN for this session up to the capture (§2 + §3), except the `GetProcAddress`/SecuROM `TlsSetValue` hole named in §3.
- FCW 0x027F on tid 15824: PROVEN at capture time only (one snapshot, thread parked in ntdll at 0x77C7718C).
  No PC-changing instruction anywhere in `.text`, and the one `.text` PC changer (`FUN_007c9410`, Scaleform) restores
  and is off the Havok path: PROVEN.
  NOT DETERMINED during the step itself: code outside `.text` that runs on tid 15824 between frames or inside the step —
  system DLLs (d3d9, MSVCR80 math routines, drivers) and the SecuROM sections (Stext/.securom, incl. the VM) — was not swept.
  A live FCW read inside `FUN_008fd040` (or a capture whose main-thread EIP is in it) would close this.
- tid 11456 (0x007F) = cpu-1 worker: PROVEN. Worker = D3D CreateDevice thread: INFERRED (24-bit matches D3D9 without
  FPU_PRESERVE — recall — and the worker creates the window; the thread that calls CreateDevice is not proven).
- Observed in this capture: busy flags `[0x19F9040]`=1 (cpu 0) and `[0x19F916C]`=1 (cpu 1); worker `TLS[24]`/`TLS[25]` = NULL.
