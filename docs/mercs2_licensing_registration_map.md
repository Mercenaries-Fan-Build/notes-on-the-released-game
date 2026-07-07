# Mercenaries 2 — Licensing & Registration Code Map

Reverse-engineering notes for the preservation / fan-build project. Maps every
piece of licensing, registration, and copy-protection code found in the engine
decompilation, and ties it back to the registry data we backed up.

Sources (all under `output/_ghidra/`):
- `mercs2_unpacked.exe_decomp.txt` — **SecuROM-unpacked** dump (~1.28M lines). PRIMARY; exposes the DRM runtime that the on-disk `.securom` section hides.
- `Mercenaries2-signed.exe_decomp.txt`, `Mercenaries2.A237.exe_decomp.txt` — on-disk packed builds (registration/activation code not visible there; obfuscated by the packer).
- `Mercenaries2_exe_findings.txt` — packed section layout.

Registry data backed up at `backups/registry/2026-06-30/`. The live `ergc`
registration code is `ANEEQ93JZXDRRD6CHBHQ`.

> There are **two independent systems**. Keep them separate:
> 1. **EA game-level registration** — reads the `ergc` code from the registry (no validation locally; the code is just carried for online/telemetry).
> 2. **SecuROM v7 DRM** — the actual copy protection: disc authentication, product activation / unlock codes, and a kernel-touching access service.

---

## 1. EA game-level registration (the `ergc` / "CD-Key")

### `FUN_0074b760` — SettingsSerializer::Init  (the registry reader)
`mercs2_unpacked.exe_decomp.txt:444543` · size 810 · callers `0x00631b42`, `0x02484c66`

Reads, in order:

| Registry key | Value | Lands in global | Fallback on failure |
|---|---|---|---|
| `HKLM\SOFTWARE\Electronic Arts\EA Games\Mercenaries 2 World in Flames\ergc` | (default) | `DAT_00f7f1d0` (~256B) | `"No CD Key Found"` |
| `HKLM\SOFTWARE\EA Games\Mercenaries 2 World in Flames` | `Language` | `s_English__UK__00f7efc8` | `"Invalid Language"` |
| same | `Locale` | `s_en_UK_00f7f150` | `"Invalid Locale"` |
| same | `Region` | `s_mercenaries2_enru_00f7f250` | `"Invalid Region"` |
| `…\Mercenaries 2 World in Flames\1.0` | `Language` (DWORD) | `DAT_00cfdd1c` | `0xffffffff` |

- The `ergc` path is assembled at `444578` with format `"%s\%s\%s\%s\%s"` from the literals SOFTWARE / Electronic Arts / EA Games / Mercenaries 2 World in Flames / `ergc`.
- **`DAT_00f7f1d0` is the runtime CD-Key.** It is read verbatim from the registry — there is **no local checksum / validation** of the key here.

### `FUN_00847fe0` — CD-Key packager
`mercs2_unpacked.exe_decomp.txt:634347` · size 757 · no in-binary callers (init/telemetry entry)

- Calls `FUN_00647010()` (a 4-byte accessor returning `*(param+0x20)`) to get a region/language id.
- Branches on region id `0xbba` / `0xb4` / `0xb6` / `0xbbc` (+ default), each selecting a different locale-string triple, then copies `DAT_00f7f1d0` (the CD-Key) byte-by-byte into a local struct.
- Packages `{key, region strings}` and passes it to `thunk_FUN_024b5390(…, 2, 0)` — a thunk in the unpacked high-memory (`0x024xxxxx`) SecuROM-mapped region. **Interpretation (not proven):** this is the hand-off of key+region to the online/telemetry/DiP channel; the data sink is in packed code.

### `FUN_006cc920` — activation status callback
`mercs2_unpacked.exe_decomp.txt:~370880` · size 260 — emits `unlockSuccess` / `unlockFailed` events (`s_unlockSuccess_00bcfdac`, `s_unlockFailed_00bcfe68`).

---

## 2. SecuROM v7 DRM

### 2a. Packed-image layout (proof SecuROM is present)
`Mercenaries2_exe_findings.txt:13-19` — packed exe sections:
- `.securom` `023e9000–037005f7` (20 MB, RWX) — encrypted DRM blob
- `Stext / Sitext / Srdata / Sdata / Sidata` — SecuROM runtime
- `reloaded 03701000` — dumped/reconstructed-image marker

Some real engine code is wrapped into the high `0x024xxxxx` region (e.g. `PgHardpoints::FindTransforms` ← `FUN_02467440`), i.e. SecuROM virtualized/relocated parts of the engine.

### 2b. Product activation / unlock-code layer

**`FUN_01ea1b87` — unlock-code state machine**
`mercs2_unpacked.exe_decomp.txt:1104727` (range …1105057) · size 1401 · caller `FUN_01ea2100`
- Maps SecuROM status codes → messages. Key codes:
  - `0x33` → **"unlock code is valid"** → function returns **1** (success).
  - `0x07` invalid format · `0x08` invalid CPA · `0x09` invalid · `0x0b` expired · `0x0c` revoked · `0x11` activation failed · `0x20` blacklisted (already used) · `0x21` empty.
  - Server-side: `0x2c` too many activations in timeframe · `0x2d` too many total · `0x37` too many on same PC · `0x38` too many on different PCs · `0x2e` wrong/invalid serial · `0x3b`/`0x3c` serial revoked too often.
- This confirms an **online activation** model (server-issued unlock codes, hardware/CPA binding, grace periods).

**`FUN_01bbb1c8` — activation DLL loader / UI dispatch**
`mercs2_unpacked.exe_decomp.txt:1010546` · size 599 · callers `FUN_01a74804`, `FUN_01a74ab6`
- `LoadLibraryA(param_3)` then `GetProcAddress` for the SecuROM activation-UI exports:
  `welcome_dialog`, `error_dialog`, `activate_dialog`, `activate_manual_dialog`,
  `activate_manual_get_request_dialog`, `progress_dialog`, `set_progress`,
  `cancel_progress_dialog`, `set_lang_ini_file`, `activate_offline_dialog`,
  `activation_successful_dialog` (`DAT_0211ab8c`, called at `1010657`), `set_package_name`.
- (DLL name is built by the caller; this is the standard SecuROM PA "Act" UI module.)

**`FUN_01a74804` — activation trigger / gate**
`mercs2_unpacked.exe_decomp.txt:988771` · size 690 · callers `FUN_01a74dc1`, `FUN_01a75098`
- Builds the activation request (license-key buffer via `FUN_01a7114f`, hw data via `FUN_01ae4730` into a `VirtualAlloc(0x208)` block), calls `FUN_01bbb1c8`, returns bool (1=activated).
- Gate is in caller `FUN_01a74dc1` (`989095`): `if (ret==1)` continue game init; else error branch `989101-989103` closes the handle and blocks progression.

**Anti-tamper / profiler**
- `WaitNamedPipeA("\\.\pipe\SecuROM_Profiler", 100)` at `983250` (+ open at `983254`).
- Window class `"SonyDADC SecuROM"` registered/created at `1015632`/`1015643`.

### 2c. Disc authentication (original-media check)

Region anchors → functions (all in `mercs2_unpacked.exe_decomp.txt`):

| Function | Lines | Role |
|---|---|---|
| `FUN_01b9dc90` | 1002461–1002490 | reads `SYSTEM\CurrentControlSet\Services\Cdrom\Enum` → `Count` |
| `FUN_01b9e970` | 1003119–1003183 | drive scan A–Z via `GetDriveTypeA`==5, opens `\\.\<X>:` |
| `FUN_01b9dda0` | 1002527–1002690 | per-drive props from `SYSTEM\MountedDevices` + SCSI passthrough |
| `FUN_01b9ec00` | 1003275–1003600 | CD enumeration via MountedDevices; `DeviceIoControl 0x41018` |
| `FUN_01b9f350` | 1003630–1003875 | `Enum\SCSI`: reads Manufacturer/ProductId/RevisionLevel/SCSITargetID/SCSILUN/CurrentDriveLetterAssignment and compares to expected disc signature |
| `FUN_01b9f820` | 1003879–1004129 | detailed device-signature extraction; `DeviceIoControl 0x2d1400` SCSI inquiry |
| `FUN_01bb9630` | 1008598–1008675 | `HKCC\Config Manager\Enum`, matches `"CDROM"` devices |
| `FUN_01ba00b0` | 1004280+ | ASPI command sequence (drives the above; READ TOC etc.) |

Low-level disc access:
- Dynamically loads `WNASPI32.DLL` (`GetASPI32SupportInfo`, `SendASPI32Command`) and `PID32.DLL` (SecuROM crypto: `L16load/getacc/putacc/unload`) — `FUN_01b9f160` ~1003534.
- Error codes: `0x80000a00` WNASPI32 missing · `0x80000a02/03/04` ASPI proc/adapter · `0x80000b10` PID32 load fail.

### 2d. Local activation state + access service

**UserData files** — `FUN_01c85f77` (1020468) + `FUN_01c85ff0` (1020497):
- `%APPDATA%\SecuROM\UserData\securom_v7_01.{bak,dat,tmp}` (folder via `SHGetSpecialFolderPathA` CSIDL 0x23/0x1a). This is the encrypted local activation/ticket store.

**`Software\SecuROM\ShellExtInstallPrompt`** — `FUN_01c85bf1` (1020244): HKCU key, default value set to `"0"`.

**UserAccess7 service** (kernel access driver, V7):
- `FUN_01c93a45` (1036748) — `CreateServiceA("UserAccess7","SecuROM User Access Service (V7)", … type 0x10 own-process, start 2 auto)` then `StartServiceA`, polls for RUNNING.
- `FUN_01c938af` (1036631) query · `FUN_01c939a4` (1036704) stop+`DeleteService` · `FUN_01c93ae4` (1036787) orchestrates query→stop→create→start.
- Request pipe `\\.\pipe\UserAccess7Req` (~1089786).

---

## 3. End-to-end flow (as the code shows)

1. `SettingsSerializer::Init` (`FUN_0074b760`) reads `ergc` → `DAT_00f7f1d0` (no local check).
2. SecuROM PA gate at startup: `FUN_01a75098`/`FUN_01a74dc1` → `FUN_01a74804` → `FUN_01bbb1c8` loads the activation-UI DLL.
3. If not already activated, unlock-code flow runs; `FUN_01ea1b87` validates the server/unlock status (`0x33`=valid). Result persisted in `securom_v7_01.dat`.
4. Disc-auth functions (2c) verify media signature via ASPI/SCSI + registry enumeration.
5. `UserAccess7` service provides the runtime access channel.
6. CD-Key + region packaged by `FUN_00847fe0` and handed to `thunk_FUN_024b5390` (online/telemetry sink — destination in packed code, not yet traced).

## 4. Open / unproven
- Exact data sink of `thunk_FUN_024b5390` (telemetry vs DiP vs Nucleus auth) — lands in the packed `.securom` region; needs x32dbg on the live process.
- Activation-UI DLL filename (built by caller of `FUN_01bbb1c8`).
- Whether retail activation is fully offline-capable (`activate_offline_dialog` export exists).
