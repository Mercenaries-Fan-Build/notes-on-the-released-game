# Online Connectivity & Bonus Content Checking — Native Implementation

Binary analysis of how the Mercenaries 2 PC main menu gates online features and
bonus/DLC content at the C++ level. All addresses are virtual addresses (VA) from
the running process with image base 0x00400000.

## Section Layout (Runtime)

| Section    | Base       | Size      | Notes |
|------------|------------|-----------|-------|
| `.text`    | 0x00401000 | 0x704000  | Original game code |
| `.rdata`   | 0x00B05000 | 0x0F1000  | Read-only data (strings, vtables, binding tables) |
| `.data`    | 0x00BF6000 | 0xE04000  | Read-write globals |
| `Stext`    | 0x1A49000  | 0x63B000  | SecuROM unpacked code |
| `.securom` | 0x23E9000  | 0x1318000 | SecuROM protection |

---

## 1. `IsOnlineConnected()` — Implementation Details

### Lua Binding

| Property | Value |
|----------|-------|
| String in .rdata | `"IsOnlineConnected"` at **0x00BB8078** |
| Binding table entry | **0x00B99940**: `{0x00BB8078, 0x005CAD10}` |
| C++ function VA | **0x005CAD10** |
| Lua table | `Net` (table name string at 0x00BB8154) |

Three Lua names share the **same C++ function** at 0x5CAD10:

| Lua Name | String VA | Table Entry VA |
|----------|-----------|----------------|
| `Net.IsPlatformConnected` | 0x00BB8140 | 0x00B998D0 |
| `Net.IsConnectedToInternet` | 0x00BB8118 | 0x00B998E0 |
| `Net.IsOnlineConnected` | 0x00BB8078 | 0x00B99940 |

### ASI Hook (Installed but Never Called)

The first 5 bytes at 0x5CAD10 are overwritten by `dlc_enable.asi`:

```
005CAD10  jmp 0x704F1890       ; E9 hook → ASI code
```

The ASI hook at **0x704F1890** unconditionally returns `true`:
```
704F1890  sub esp, 0x08
704F1893  mov eax, [0x704FA1D0]     ; one-time init flag
704F1898  mov edx, [esp+0x0C]       ; Lua state ptr
704F189C  test eax, eax
704F189E  jz  init_path             ; first call → atomically init
704F18A0  mov eax, [edx+0x08]       ; Lua stack top
704F18A3  mov [eax], 0x01           ; value = true (1)
704F18A9  add eax, 0x08
704F18AC  mov [eax-0x04], 0x01      ; type = LUA_TBOOLEAN (1)
704F18B3  mov [edx+0x08], eax       ; advance stack
704F18B6  mov eax, 0x01             ; return 1 result
704F18BB  add esp, 0x08
704F18BE  ret
```

**STATUS: NOT WORKING.** Although the hook is correctly installed at the
right address, `IsOnlineConnected` is **never observed being called** during
normal gameplay. The shell Lua scripts in `shell.wad` do not appear to invoke
this function in any reachable code path — breakpoints on this address never
fire. This means the Extras menu gating logic either uses a different check,
is unreachable from the current shell flow, or the relevant shell script
bytecode takes a different branch before reaching the call. The exact reason
the function is never called remains an open research question.

### Original Function (Reconstructed)

The original function was destroyed by the 5-byte JMP hook. However, the
adjacent function `ShouldPlayOnline` at 0x5CAD50 (not hooked) reveals the
pattern:

```
005CAD50  push ebx
005CAD51  mov bl, byte ptr [0x00DFBD8C]   ; ← read global flag
005CAD57  push esi
005CAD58  mov esi, [esp+0x0C]              ; Lua state
005CAD5C  mov eax, 0x01                    ; expect 1 arg
005CAD61  mov ecx, esi
005CAD63  call 0x0085D5D0                  ; validate Lua args
005CAD68  test eax, eax
005CAD6A  jnz continue
005CAD6C  pop esi / pop ebx / ret          ; bad args → bail
continue:
005CAD6F  mov eax, [esi+0x08]              ; Lua stack top
005CAD72  xor ecx, ecx
005CAD74  test bl, bl                       ; was flag non-zero?
005CAD76  setnz cl                          ; cl = (flag != 0) ? 1 : 0
005CAD79  mov [eax+0x04], 0x01             ; type = LUA_TBOOLEAN
005CAD80  mov [eax], ecx                    ; value = 0 or 1
005CAD82  add [esi+0x08], 0x08             ; advance stack
005CAD86  pop esi
005CAD87  mov eax, 0x01                     ; return 1 result
005CAD8C  pop ebx
005CAD8D  ret
```

The original `IsOnlineConnected` followed this same pattern but read from a
different global address (destroyed by the hook). The surviving bytes at
offset +5 from the hook (`7C 01`) suggest the original address was in the
**0x017Cxxxx** range — likely near the FESL connection flag at 0x017C0BBF.

### What It Checks

A single **byte flag** in the `.data` section. When the FESL client
successfully connects and authenticates to `fesl.ea.com`, this flag is set
to non-zero. The function returns it as a Lua boolean.

---

## 2. `HasPlayerUnlockedCode()` — Implementation Details

### Lua Binding

| Property | Value |
|----------|-------|
| String in .rdata | `"HasPlayerUnlockedCode"` at **0x00BB7924** |
| Binding table entry | **0x00B99BA0**: `{0x00BB7924, 0x005CB6B0}` |
| C++ function VA | **0x005CB6B0** |

### ASI Hook (Installed but Never Called)

```
005CB6B0  jmp 0x704F1490       ; E9 hook → ASI code
```

The ASI hook at **0x704F1490** unconditionally returns `true`:
```
704F1490  mov edx, [esp+0x04]       ; Lua state ptr
704F1494  mov eax, [edx+0x08]       ; Lua stack top
704F1497  mov [eax], 0x01           ; value = true (1)
704F149D  add eax, 0x08
704F14A0  mov [eax-0x04], 0x01      ; type = LUA_TBOOLEAN (1)
704F14A7  mov [edx+0x08], eax       ; advance stack
704F14AA  mov eax, 0x01             ; return 1 result
704F14AF  ret
```

**STATUS: NOT WORKING.** Same as `IsOnlineConnected` — the hook is installed
but `HasPlayerUnlockedCode` is **never observed being called** during gameplay.
Breakpoints at this address never fire. The shell scripts apparently do not
reach the code path that invokes this function.

### Original Function (Reconstructed)

The original first 7 bytes were:
```
005CB6B0  cmp byte ptr [0x00DFBD74], 0x00   ; 80 3D 74 BD DF 00 00
```
(5 bytes overwritten by hook + 2 surviving bytes `00 00` at +5 confirm this
encoding: the last address byte + the `0x00` immediate.)

Full original flow:
```
005CB6B0  cmp byte ptr [0x00DFBD74], 0x00   ; check "online ready" flag
005CB6B7  push esi
005CB6B8  mov esi, [esp+0x08]               ; Lua state
005CB6BC  mov [esp+0x08], esi
005CB6C0  jz return_false                    ; if not online-ready → false
005CB6C2  cmp byte ptr [0x017C0BBF], 0x00   ; check FESL connection flag
005CB6C9  jz return_false                    ; if FESL disconnected → false
005CB6CB  movzx eax, byte ptr [0x00DFBD98]  ; read actual unlock code status
005CB6D2  push eax
005CB6D3  lea esi, [esp+0x0C]
005CB6D7  call 0x004B86E0                    ; push value onto Lua stack
005CB6DC  pop esi
005CB6DD  ret

return_false:                                ; (0x005CB6DE)
005CB6DE  mov eax, 0x01
005CB6E3  mov ecx, esi
005CB6E5  call 0x0085D5D0                    ; validate Lua args
... push boolean false onto stack, return 1 ...
```

### Three-Stage Gate

The original `HasPlayerUnlockedCode` implements a three-stage check:

1. **`byte [0x00DFBD74]`** — "Online ready" flag. Set during game startup
   when the network subsystem initializes. Currently **0x01** (true).

2. **`byte [0x017C0BBF]`** — FESL connection established flag. Set when the
   game successfully completes TLS handshake + authentication with
   `fesl.ea.com`. Currently **0x00** (false — EA servers are offline).

3. **`byte [0x00DFBD98]`** — Actual "player has unlocked code" status. This
   byte holds the server's response to the entitlement query. Only consulted
   if both previous checks pass. Currently **0x00** (not unlocked).

If either gate 1 or gate 2 fails, the function short-circuits to return
`false` without checking the actual unlock status. This means the game
**requires an active FESL connection** before it will even report unlock
code status.

---

## 3. Global Flags — Current State

| Address | Size | Name | Current Value | Used By |
|---------|------|------|---------------|---------|
| 0x00DFBD74 | byte | Online ready | **0x01** (true) | HasPlayerUnlockedCode gate 1 |
| 0x00DFBD8C | byte | ShouldPlayOnline | **0x01** (true) | Net.ShouldPlayOnline |
| 0x00DFBD98 | byte | Unlock code status | **0x00** (false) | HasPlayerUnlockedCode gate 3 |
| 0x017C0BBF | byte | FESL connected | **0x00** (false) | HasPlayerUnlockedCode gate 2, UpdatePresence |
| 0x017C0BC8 | dword | Online enabled | **0x01** (1) | Net.IsOnlineEnabled / Net.IsMatchmakingInternet |

The FESL connected flag at 0x017C0BBF is 0x00 because EA's FESL servers
(`fesl.ea.com`) have been decommissioned since ~2014. Without the ASI hook,
both `IsOnlineConnected` and `HasPlayerUnlockedCode` would return `false`.

---

## 4. FESL Client Architecture

### Server Configuration

| String | VA | Description |
|--------|----|-------------|
| `"fesl.ea.com"` | 0x00B5FBAC | FESL server hostname |
| `"feslPort: %d\n"` | 0x00B5E371 | Port logging format |
| `"FeslServiceId: %d (0x%x)\n"` | 0x00B5E340 | PC service ID log |
| `"360FeslServiceId: %d (0x%x)\n"` | 0x00B5E33D | Xbox 360 service ID log |
| `"protocolVersion"` | 0x00B5FCE4 | FESL protocol version field |
| `"encryptedLoginInfo"` | 0x00B616A8 | Login credential field |
| `"displayName"` | 0x00B616BC | User display name field |
| `"lkey"` | 0x00B616C8 | Login key field |
| `"\tclientString: \"%s\"\n"` | 0x00B5E381 | Client identification string log |

### FESL Services

The game registers handlers for these FESL service types:

| Service | String VA | Purpose |
|---------|-----------|---------|
| `"fsys"` | 0x00B5D3C8 | Connection handshake / system |
| `"acct"` | 0x00B5D444 | Account authentication |
| `"subs"` | 0x00B5D108 | Subscriptions / entitlements / DLC |
| `"recp"` | 0x00B5D110 | Receipts |
| `"rank"` | 0x00B5D118 | Rankings / leaderboards |
| `"thtr"` | 0x00B5D100 | Theater (matchmaking / game sessions) |
| `"club"` | 0x00B5D3D0 | Clubs / clans |
| `"asso"` | 0x00B5D3F8 | Associations (friends) |
| `"gsum"` | 0x00B5D400 | Game summary / stats |

Additional protocol elements in .rdata: `"chunk"`, `"blob"`,
`"IMBlock_voice"`, `"IMBlock_text"`, `"IMBlock_invite"`, `"IMBuddy"`,
`"gclient"`, `"csr"` (customer service).

### FESL Initialization Sequence (Inferred)

1. Game checks `IsOnlineEnabled` → reads `dword [0x017C0BC8]`
2. If enabled, connects to `fesl.ea.com` on the configured port via TLS
   (OpenSSL 0.9.8d — the game imports `ssleay32.dll`)
3. FESL `fsys` handshake: exchanges `protocolVersion`, `clientString`
4. FESL `acct` login: sends `encryptedLoginInfo`, receives `lkey`,
   `displayName`
5. On successful auth, sets FESL connection flag at `byte [0x017C0BBF] = 1`
6. Theater (`thtr`) connection for matchmaking/game sessions
7. Entitlement queries via `subs` service

### Server Config Logging

The format string at 0x00B5E380:
```
\tclientString: "%s"
  ServerInfo:
\tNpIdLookupThreadPrio: %d
\tMaxActiveNpIdLookups: %d
\tMaxDefaultSimultaneousTxnCount: %d
```
indicates the FESL client logs its configuration on startup, including the
client identification string and connection parameters.

---

## 5. Entitlement / DLC Query System

### Transaction Types (subs Service)

The entitlement system uses the FESL `subs` service. Transaction type
strings and their dispatch table reside in `.data` at **0x00CDE8E0**:

| Transaction Type | String VA | Description |
|-----------------|-----------|-------------|
| `ApplyPricingSelection` | 0x00B61554 | Apply a pricing/purchase selection |
| `GetEntitlementByBundle` | 0x00B6156C | **Query entitlement status for a content bundle** |
| `GetCouponsByBundle` | 0x00B61584 | Query coupons for a bundle |
| `GetPricingOption` | 0x00B61598 | Get pricing info for content |
| `SuspendEntitlement` | 0x00B615AC | Suspend an entitlement |
| `GetPayingStatus` | 0x00B615C0 | Check user's payment status |
| `GetSubscriptionAbility` | 0x00B615D0 | Check subscription capability |
| `GetPricingSelection` | 0x00B61540 | Get active pricing selection |
| `GetPricingSelectionsByBundle` | 0x00B61530 | Get pricing options for a bundle |
| `GetPricingSelectionsByCode` | 0x00B6150A | **Get pricing options by promo code** |

### Dispatch Table Structure (0x00CDE8E0)

Each entry is 12 bytes: `{string_ptr, reserved, service_name_ptr}`:

```
CDE8E0: [ApplyPricingSelection]  [00000000] ["subs"]
CDE8EC: [GetEntitlementByBundle] [00000000] ["subs"]
CDE8F8: [GetCouponsByBundle]     [00000000] ["subs"]
CDE904: [GetPricingOption]       [00000000] ["subs"]
CDE910: [SuspendEntitlement]     [00000000] ["subs"]
CDE91C: [GetPayingStatus]        [00000000] ["subs"]
CDE928: [GetSubscriptionAbility] [00000000] ["subs"]
```

### Entitlement Response Fields

| Field Name | String VA | Description |
|-----------|-----------|-------------|
| `entitlementStatus` | 0x00B5F724 | Status code (active/suspended/etc.) |
| `entitlementStatusDesc` | 0x00B5F714 | Human-readable status description |
| `entitlementSuspendDate` | 0x00B5F70C | Suspension date if suspended |
| `pricingOptionId` | 0x00B5F6F8 | Pricing option identifier |

### Entitlement Query Flow

1. Lua menu code would call `Net.IsOnlineConnected()` → returns `true` (via ASI hook
   or real FESL connection) — **however, this call is never observed at runtime**
2. If online, menu would enable "Extras" / bonus content options
3. Menu code would call `Net.HasPlayerUnlockedCode()` → checks three global flags
4. The actual entitlement check involves the `subs` service:
   - Client sends `GetEntitlementByBundle` transaction to FESL
   - Server responds with `entitlementStatus` and related fields
   - Result is stored in `byte [0x00DFBD98]`
5. The `GetPricingSelectionsByCode` transaction handles promotional/bonus codes

### DLC Session Fields

In the game session/match description (Theater service), these fields indicate
DLC content:

| Field | String VA | Purpose |
|-------|-----------|---------|
| `"DlcMapId"` | 0x00BE2C18 | DLC map identifier (sent in session info) |
| `"IsDLC"` | 0x00BE2C24 | Boolean flag: session uses DLC content |

These are part of the Theater (`thtr`) game session description sent when
creating or joining multiplayer games.

---

## 6. Bonus Code / Unlock Code System

### Architecture

The bonus code system does **not** use local file storage or registry keys.
It operates entirely through the FESL entitlement infrastructure:

1. No strings like `"UnlockCode"`, `"PromoCode"`, `"Redeem"`, `"CDKey"`,
   `"SerialNumber"`, or `"BonusContent"` exist in `.rdata` — confirmed by
   exhaustive pattern search.

2. The `GetPricingSelectionsByCode` transaction (at 0x00B6150A) is the
   mechanism for code redemption. This sends a promotional code to the FESL
   `subs` service, which validates it server-side and grants the
   corresponding entitlement.

3. The result is stored in the global at **0x00DFBD98** and queried via
   `HasPlayerUnlockedCode`.

### Implications

- **No offline code validation** — all bonus/promo codes require a live FESL
  connection to validate.
- **No local persistence** — unlock status is stored server-side and
  re-queried each session via `GetEntitlementByBundle`.
- The ASI mod hooks `HasPlayerUnlockedCode` to always return `true`, but
  **the function is never called** by the shell scripts — the hook is
  ineffective for enabling bonus content via the menu.

---

## 7. Theater (Matchmaking) Message Types

The Theater service (`thtr`) dispatch table follows the `subs` entries in
`.data` starting at **0x00CDE934**. Each entry: `{handler_ptr, type_tag_4cc, service_name_ptr}`.

Handler function: **0x00BA8B09** (common Theater message handler)

| Type Tag (4CC) | Purpose |
|----------------|---------|
| `CONN` | Connect to Theater server |
| `USER` | Authenticate user |
| `RLST` | Room list |
| `RDAT` | Room data |
| `LLST` | Lobby list |
| `LDAT` | Lobby data |
| `GLST` | Game list |
| `GDAT` | Game data |
| `GDET` | Game detail |
| `PDAT` | Player data |
| `CGAM` | Create game |
| `UGAM` | Update game |
| `UGDE` | Update game detail |
| `UPLA` | Update player |
| `UBRA` | Update bracket |
| `EGAM` | Enter game |
| `EGEG` | Enter game (echo/confirm) |
| `ECNL` | Event cancel |
| `EGRQ` | Enter game request |
| `EGRS` | Enter game response |
| `QLEN` | Queue length |
| `PENT` | Player entered |

Session descriptor fields at ~0x00B5F730:
`GID`, `LID`, `PID`, `UGID`, `HPID`, `QLEN`, `QPOS`, `REASON`, `SECRET`,
`RESERVE-IDS`, `B-maxGameSize`, `RT`

---

## 8. Complete Net.* Lua Binding Table

The `Net` Lua table binding array is in `.rdata` at **0x00B998D0**, preceded
by an 8-byte header at 0x00B998C8 (hash/metadata: `0x38D1B717 0x3C23D70A`).
The table name string `"Net"` is at 0x00BB8154.

Each entry is 8 bytes: `{const char *name, lua_CFunction func}`, terminated
by `{NULL, NULL}` at **0x00B99BB0**.

### Network State Functions

| # | Lua Name | Func VA | Notes |
|---|----------|---------|-------|
| 1 | `IsPlatformConnected` | 0x005CAD10 | **Hooked (never called)** — same impl as IsOnlineConnected |
| 2 | `IsMultiplayer` | 0x005C66C0 | |
| 3 | `IsConnectedToInternet` | 0x005CAD10 | **Hooked (never called)** — alias for IsOnlineConnected |
| 4 | `IsEnabled` | 0x005C6710 | |
| 5 | `IsActive` | 0x005C6750 | |
| 6 | `IsLobby` | 0x005C6790 | |
| 7 | `IsClient` | 0x005C67D0 | |
| 8 | `IsServer` | 0x005C6810 | |
| 9 | `IsDedicated` | 0x005C6850 | |
| 10 | `AutoLobby` | 0x005C6850 | Same impl as IsDedicated |
| 11 | `AutoClient` | 0x005C6850 | Same impl as IsDedicated |
| 12 | `AutoServer` | 0x005C6890 | |
| 13 | `GetHostName` | 0x005C68E0 | |
| 14 | `IsMatchmakingInternet` | 0x005CACC0 | **Hooked (never called)** — checks `[0x017C0BC8]` |
| 15 | `IsOnlineConnected` | 0x005CAD10 | **Hooked (never called)** — reads global flag |
| 16 | `ShouldPlayOnline` | 0x005CAD50 | Reads `byte [0x00DFBD8C]` |
| 17 | `DialogBoxPlayOffline` | 0x005CAD90 | Shows offline dialog |
| 18 | `DialogBoxMustBeSignInToLive` | 0x005CAE40 | Xbox Live sign-in prompt |
| 19 | `IsOnlineEnabled` | 0x005CACC0 | **Hooked (never called)** — alias for IsMatchmakingInternet |
| 20 | `DialogBoxPlayLocal` | 0x005CAD90 | Same impl as DialogBoxPlayOffline |

### Session/Lobby Functions

| # | Lua Name | Func VA |
|---|----------|---------|
| 21 | `EnterLobby` | 0x005C69E0 |
| 22 | `ResetServerList` | 0x005C6A40 |
| 23 | `ConnectToServer` | 0x005C6AA0 |
| 24 | `StartServer` | 0x005C6C40 |
| 25 | `Stop` | 0x005C6D30 |
| 26 | `QuitGame` | 0x005C6D90 |
| 27 | `EnterFriendsLobby` | 0x005C6910 |
| 28 | `ExitFriendsLobby` | 0x005C6980 |

### Co-op Event Functions

| # | Lua Name | Func VA |
|---|----------|---------|
| 29 | `SendEvent_ShowMessage` | 0x005C6DF0 |
| 30 | `SendEvent_AddObjective` | 0x006D5640 |
| 31 | `SendEvent_RemoveObjective` | 0x006D5640 |
| 32 | `SendEvent_AddRadarObjective` | 0x005C7150 |
| 33 | `SendEvent_RemoveRadarObjective` | 0x005C79F0 |
| 34 | `SendEvent_AddMarkerObjective` | 0x005C74B0 |
| 35 | `SendEvent_RemoveMarkerObjective` | 0x005C7BA0 |
| 36 | `SendEvent_AddPdaObjective` | 0x005C77E0 |
| 37 | `SendEvent_RemovePdaObjective` | 0x005C7AC0 |
| 38 | `SetLastHeroTeleportLocation` | 0x005C8040 |
| 39 | `SendEvent_TeleportPlayer` | 0x005C7C70 |
| 40 | `SendEvent_TeleportPlayerToHardPoint` | 0x005C7E00 |
| 41 | `SendEvent_Fanfare` | 0x005C8180 |
| 42 | `SendEvent_CloseFanfare` | 0x005C84C0 |
| 43 | `SendEvent_ObjectiveMessage` | 0x005C8530 |
| 44 | `SendEvent_Support` | 0x005C8680 |
| 45 | `SendEvent_AddSupportItem` | 0x005C9250 |
| 46 | `SendEvent_RemoveSupportItem` | 0x005C9250 |
| 47 | `SendEvent_RecruitsUnlocked` | 0x005CB560 |
| 48 | `SendEvent_RevivePlayer` | 0x005C8900 |
| 49 | `SendEvent_RequestPosition` | 0x005C8A50 |
| 50 | `SendEvent_SetObjectiveTraySlotText` | 0x005C8A90 |
| 51 | `SendEvent_SetObjectiveTraySlotImage` | 0x005C8C20 |
| 52 | `SendEvent_ClearObjectiveTraySlot` | 0x005C8DF0 |
| 53 | `SendEvent_ShowMovie` | 0x005C8F50 |
| 54 | `SendEvent_HideMovie` | 0x005C9080 |
| 55 | `BeginLayerEventGroup` | 0x005C90F0 |
| 56 | `EndLayerEventGroup` | 0x005C9130 |
| 57 | `GrantAchievement` | 0x005C9170 |
| 58 | `KickPlayer` | 0x005C91E0 |
| 59 | `ApplyCachedFactionRelations` | 0x005C9210 |
| 60 | `SendEvent_EnableHeroWeapons` | 0x005C9250 |
| 61 | `SendEvent_AddDangerousBuilding` | 0x005C9290 |
| 62 | `SendEvent_RemoveDangerousBuilding` | 0x005C93B0 |
| 63 | `SendEvent_SetOccupiedDangerousBuilding` | 0x005C94C0 |
| 64 | `SendEvent_AddRandomDangerousBuilding` | 0x005C9560 |

### Bonus Content / Presence Functions

| # | Lua Name | Func VA | Notes |
|---|----------|---------|-------|
| 65 | `HasPlayerUnlockedCode` | 0x005CB6B0 | **Hooked (never called)** — three-stage gate |
| 66 | `UpdatePresence` | 0x005CB710 | Checks `[0xDFBD74]` and `[0x017C0BBF]` |

---

## 9. Menu Visibility → Online Check Flow

### Lua Side (Shell Scripts)

The "Extras" menu in the main menu shell is gated by Lua code like:

```lua
if Net.IsOnlineConnected() then
    -- enable "Extras" / "Bonus Content" menu items
    if Net.HasPlayerUnlockedCode() then
        -- show unlocked DLC content
    end
end
```

### Native Flow

```
Menu Click → Lua Shell → Net.IsOnlineConnected()
                              │
                     [original: read byte flag]
                     [hooked: always true]
                              │
                              ▼
                    true → enable Extras menu
                              │
                         Net.HasPlayerUnlockedCode()
                              │
                     ┌────────┴────────────┐
                     │ Original             │ Hooked (ASI)
                     │                      │
                     │ 1. [0xDFBD74]!=0?    │ return true
                     │ 2. [0x017C0BBF]!=0?  │
                     │ 3. read [0xDFBD98]   │
                     │    push to Lua       │
                     └─────────────────────-┘
                              │
                              ▼
                    true → show DLC items
```

### The IsOnlineEnabled / IsMatchmakingInternet Function (0x5CACC0)

Also hooked by the ASI. Original code checks:

```
005CACC0  [hooked first 5 bytes]
005CACC5  [residual 00 00]
005CACC7  push ebx
005CACC8  push esi
005CACC9  jz set_false                    ; (from destroyed comparison)
005CACCB  cmp dword ptr [0x017C0BC8], 1   ; check "online enabled" dword
005CACD2  jnz set_false
005CACD4  mov bl, 0x01                     ; result = true
005CACD6  jmp push_result
set_false:
005CACD8  xor bl, bl                       ; result = false
push_result:
005CACDA  ... standard Lua boolean push ...
```

This function gates whether online multiplayer/matchmaking is available.
It reads the global **dword** at `0x017C0BC8` (currently 1 = enabled).

---

## 10. Connection Between Online Check and Menu Visibility

### Without ASI Hook (Original Behavior)

1. Game starts → initializes network subsystem → sets `[0xDFBD74] = 1`
2. Game attempts TLS connection to `fesl.ea.com` via OpenSSL 0.9.8d
3. If FESL connects + authenticates → sets `[0x017C0BBF] = 1`
4. FESL `subs` service queried with `GetEntitlementByBundle` → response
   populates `[0xDFBD98]` with unlock status
5. Lua calls `IsOnlineConnected()` → reads connection flag → returns true
6. Lua calls `HasPlayerUnlockedCode()` → gates on 3 flags → returns
   entitlement status
7. Menu enables/disables "Extras" options based on return values

### With ASI Hook (Current Behavior — NOT WORKING)

1. `dlc_enable.asi` loads via DLL injection (placed in `scripts/` directory)
2. ASI hooks 4 functions by overwriting first 5 bytes with `E9` JMP:
   - `IsOnlineConnected` (0x5CAD10) → always returns true
   - `HasPlayerUnlockedCode` (0x5CB6B0) → always returns true
   - `IsMatchmakingInternet` (0x5CACC0) → always returns true
   - (plus additional hooks at 0x704F1C80)
3. **However, none of these hooked functions are ever called.**
   Breakpoints at these addresses never fire during normal gameplay.
   The shell Lua scripts in `shell.wad` do not appear to invoke
   `IsOnlineConnected()` or `HasPlayerUnlockedCode()` in any
   reachable code path from the main menu.
4. The Extras menu remains non-functional
5. Actual FESL connection flag `[0x017C0BBF]` remains 0x00 (disconnected)
6. Actual unlock code `[0x00DFBD98]` remains 0x00 (not unlocked)

**Open question:** Why are these Lua bindings registered but never called?
Possible explanations:
- The shell bytecode in `shell.wad` may check a different flag/function first
  and short-circuit before reaching the `IsOnlineConnected` call
- The Extras menu option may be compiled out of the PC shell scripts entirely
  (it was primarily a console feature)
- The call may happen on a code path gated by an earlier check that always
  fails (e.g. a platform check that returns false on PC)
- The `disableOnline` flag (string at 0x00BBC660) may permanently suppress
  the online code path in the shell

### ASI Hook Addresses

| Hooked Function | Original VA | Hook Target | Effect |
|----------------|-------------|-------------|--------|
| `IsOnlineConnected` | 0x005CAD10 | 0x704F1890 | Always returns `true` — **never called** |
| `HasPlayerUnlockedCode` | 0x005CB6B0 | 0x704F1490 | Always returns `true` — **never called** |
| `IsMatchmakingInternet` | 0x005CACC0 | 0x704F1C80 | Always returns `true` — **never called** |
| `IsOnlineEnabled` | 0x005CACC0 | 0x704F1C80 | (same function as above) — **never called** |

The ASI module `dlc_enable.asi` is loaded at base **0x704F0000** (size 0x17000).
Its one-time initialization flag is at **0x704FA1D0**.

**IMPORTANT:** All four hooks are correctly installed (E9 JMP patches verified
in memory) but none of the hooked functions are ever invoked during normal
gameplay. Breakpoints at these addresses never fire. The shell Lua bytecode
in `shell.wad` does not reach these call sites. Decompiling the shell scripts
is required to understand why.
