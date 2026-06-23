# Networking

Networking / online services / co-op session and replication layer of Mercenaries 2.

Provenance: symbol- and string-evidence recovered from the Xbox 360 devkit "Profile" build `Mercs2_Xenon_P.exe` (Jul 11 2008 preview, PowerPC). Offsets are PE offsets as they appear in the shared inventory. Build tree was `d:\projects\ReleaseLine\Mercs2\`. This is NOT a real `.pdb`; it is string/symbol evidence from the decompressed PE (`output/jul08_prototype/mercs2_xenon_p.pe_full.bin`).

## Overview

The networking subsystem in this build is made of three distinct, separable layers, all visible in the recovered strings:

1. **Game-side networked event / replication layer** — a family of `Net*` named callbacks and category descriptors (`NetCommand`, `NetNotify`, `NetPrimaryCategory`, `NetSubCat*`, `NetSafe*`, `NetClient*`, `NetSynchImportModule`, `NetPull`, `NetEventCallback`) that gate gameplay actions and HUD/cinematic operations so they execute correctly under client/host co-op. These appear to be the engine's replication/RPC hooks.
2. **`CNetworkManager` / `CMassiveClientCore`** — a low-level TCP/HTTP client used to talk to remote "ad servers" (the Massive in-game advertising network, `Adclient Massive Inc.`), with DNS, heartbeat, server-address arrays, request queueing and an HTTP/1.1 wrapper. Distinct from co-op multiplayer.
3. **Xbox 360 online middleware** — an `Xb360Session` / `GameManager` / `ServiceRegistrar` matchmaking and session stack built on Xbox LIVE / XLSP / System Link APIs (`XSession*`, `XNet*`, `XTitleServerCreateEnumerator`, `XOnlineGetServiceInfo`), driven by a `PlayNowOptions`-style matchmaking config (`SessionType`, `FindServer`/`AssignHost`/`ResetServer`/`ListServers`). This is the co-op multiplayer / dedicated-server path.

No `networking`-system source paths and no `Net*`/`Massive*` RTTI class names survive in the recovered `source_paths.txt` / `rtti_classes.txt` (those files cover Lua/Pal/Pangea/Xenon-graphics and 324 Pangea engine classes respectively), so class/file structure below is reconstructed from string evidence only.

## Source files

None. `output/jul08_prototype/mercs2_xenon_p.source_paths.txt` contains 48 paths (Lua-5.1.2, `Pal\*`, `Pangea\Src\*`, `pimp\*`, and Xenon `xgraphics` ucode-compiler paths); none belong to this subsystem.

## Key classes

No demangled `.?AV`/`.?AU` RTTI names for this subsystem appear in `mercs2_xenon_p.rtti_classes.txt`. The class names below are recovered from **literal strings** (assert/log text), not from the RTTI table, so they are reported as evidence rather than as confirmed RTTI:

- `CNetworkManager` / `PCNetworkManager` (string, line 12595/12598) — server-address/port manager.
- `CMassiveClientCore` (string, line 12505) — top-level Massive ad-client.
- `CRequestManager`, `CMassiveZoneManager`, `CMassiveMemoryManager`, `CMassiveSocket`, `CMassiveAdObject`, `CAddressIndexPair`, `CPortIndexPair`, `CRequestOpenSession`/`CloseSession`/`EnterZone`/`ExitZone`/`LocateService`/`ImpressionUpdate`/`Heartbeat` (strings) — the Massive request/zone/socket object graph.
- `Xb360Session` (string, line 17490) — the Xbox 360 LIVE/System-Link session wrapper.
- `GameManager` / `GameManagerHostedGame` (strings, lines 18915 / 17411) — matchmaking/session host manager.

## Symbols by area

All offsets/sections below are copy-exact from `output/jul08_prototype/inventory/networking.txt`.

### A. Networked event categories (replication descriptors)

| Offset | Section | Symbol |
|---|---|---|
| 0x0013a1c | .rdata | NetCommand |
| 0x0013a28 | .rdata | NetNotify |
| 0x00317dc | .rdata | NetCategoryInfo |
| 0x003fde0 | .rdata | NetPrimaryCategory |
| 0x003fd4c | .rdata | NetSubCatFriendOrFoe |
| 0x003fd64 | .rdata | NetSubCatIsImportant |
| 0x003fd7c | .rdata | NetSubCatInventory |
| 0x003fd90 | .rdata | NetSubCatSeatLink |
| 0x003fda4 | .rdata | NetSubCatPoweredGate |
| 0x003fdbc | .rdata | NetSubCatNodeHealth |
| 0x003fdd0 | .rdata | NetSubCatHealth |

`NetCommand`/`NetNotify` sit among gameplay-event tokens (`Weapon Events`, `Grapple Events`, `NodeState`, `Trigger` — strings lines 915-925), suggesting they are channels in the engine's event dispatch. The `NetPrimaryCategory` + `NetSubCat*` set names per-object replication categories: friend/foe relation, importance, inventory, vehicle-seat linkage, powered gates, and node/health state — i.e. which object properties are network-synced.

### B. `NetSafe*` — host-authoritative gameplay/cinematic operations

These wrap operations that must be funneled through the network-authoritative path (briefing "spiel"/asset loading, PDA blips, fanfare, cinematics, borders):

| Offset | Section | Symbol |
|---|---|---|
| 0x0046fb4 | .rdata | NetSafeHandleReporter1 |
| 0x0046fcc | .rdata | NetSafeHandleReporter2 |
| 0x0046fe4 | .rdata | NetSafeFinishedReporting |
| 0x0047000 | .rdata | NetSafeHandleReporter0 |
| 0x0047018 | .rdata | NetSafeRemoveReportingDisplay |
| 0x00470d8 | .rdata | NetSafeIsSpielLoaded |
| 0x00470f0 | .rdata | NetSafeAreBriefingAssetsLoaded |
| 0x00471c0 | .rdata | NetSafeAddPmcPdaBlip |
| 0x00471d8 | .rdata | NetSafeRemovePmcPdaBlip |
| 0x00471f0 | .rdata | NetSafeAddHqPdaBlip |
| 0x0047204 | .rdata | NetSafeRemoveHqPdaBlip |
| 0x004721c | .rdata | NetSafeLoadSpiel |
| 0x0047230 | .rdata | NetSafeUnloadSpiel |
| 0x0047244 | .rdata | NetSafeClearStarter |
| 0x0047258 | .rdata | NetSafeSetStarter |
| 0x004726c | .rdata | NetSafeLoadAssets |
| 0x0047280 | .rdata | NetSafeUnloadAssets |
| 0x0047294 | .rdata | NetSafePlayCheapCinematic |
| 0x00472b0 | .rdata | NetSafeSetupBorder |
| 0x0047690 | .rdata | NetSafeIsStarterLoaded |

### C. `NetClient*` — client-side HUD / movie / faction mirrors

Operations the client performs locally in response to host state (movie playback, faction meters/pursuit, objective tray, fanfare):

| Offset | Section | Symbol |
|---|---|---|
| 0x00472d0 | .rdata | NetClientHideMovie |
| 0x00472e4 | .rdata | NetClientShowMovie |
| 0x00472f8 | .rdata | NetClientIsMovieHiding |
| 0x0047310 | .rdata | NetClientIsMovieRunning |
| 0x00474c0 | .rdata | NetClientFactionSetValue |
| 0x00474dc | .rdata | NetClientFactionStartPursuit |
| 0x00474fc | .rdata | NetClientFactionHideMeter |
| 0x0047534 | .rdata | NetClientClearObjectiveTraySlot |
| 0x0047554 | .rdata | NetClientSetObjectiveTraySlot |
| 0x0047614 | .rdata | NetClientCloseFanfare |

(Also present in the full strings but NOT in the inventory subset: `NetClientAddBoundary`, `NetClientRemoveBoundary`, strings lines 7777-7778.)

### D. Save/economy and damage sync hooks

| Offset | Section | Symbol |
|---|---|---|
| 0x0021988 | .rdata | NetworkDamageException |
| 0x0024d74 | .rdata | ClientRestorePreSaveCash |
| 0x0024dd8 | .rdata | ClientReimburseForSave |
| 0x00475c0 | .rdata | ClientHVTFanfare |
| 0x0047180 | .rdata | NetEventCallback |
| 0x0045b28 | .rdata | NetPull |
| 0x0046e4c | .rdata | NetSynchImportModule |
| 0x0046ea4 | .rdata | NetInitializeClientFactionRelations |
| 0x0047614 | .rdata | NetClientCloseFanfare |

`NetSynchImportModule` / `NetPull` / `NetEventCallback` / `NetInitializeClientFactionRelations` wire up state synchronization and faction-relation bootstrapping for a joining client. `ClientRestorePreSaveCash` / `ClientReimburseForSave` reconcile economy state around save in co-op, and `NetworkDamageException` is damage-rule handling under networking.

### E. `CNetworkManager` server-address table

| Offset | Section | Symbol |
|---|---|---|
| 0x00a4cd8 | .rdata | NetworkManager::GetServerAddressU32 |
| 0x00a4e1c | .rdata | NetworkManager::GetServerPortU16 |
| 0x00a4e40 | .rdata | NetworkManager::GetServerHostName |
| 0x00a50fc | .rdata | ServerAddressArray |

These name the `CNetworkManager` accessors for a locked, reference-counted server address/port array used by the Massive ad client (see Notable strings; confirmed in the PC decomp — `FUN_009dff40`/`FUN_009e010a` below).

### F. Session / matchmaking / online tunables

| Offset | Section | Symbol |
|---|---|---|
| 0x002f488 | .rdata | LobbyServerAdded |
| 0x002f49c | .rdata | LobbyServerUpdated |
| 0x002f534 | .rdata | LobbyServerRemoved |
| 0x0106ae0 | .rdata | SessionType |
| 0x0106bf0 | .rdata | HostSetupTimeoutSeconds |
| 0x01032d0 | .rdata | Online_grant_01 |

`LobbyServer*` are lobby/server-list update events. `SessionType` and `HostSetupTimeoutSeconds` are matchmaking config keys parsed by `FUN_009ba4b0` (see PC decompilation cross-reference). `Online_grant_01` sits in an EASTL-string region (strings line 17327); its purpose is unclear from symbols alone, possibly an online entitlement/grant id.

### G. Faction / awareness (adjacent, in inventory)

| Offset | Section | Symbol |
|---|---|---|
| 0x0026294 | .rdata | HostileAware |
| 0x00262a4 | .rdata | HostileObservers |

Present in the networking inventory; these relate to AI hostility/awareness state that is among the replicated categories (cf. `NetSubCatFriendOrFoe`), and likely belong as much to AI as to networking. The string `HostileAware: %d` (line 3360) confirms it is a logged value.

## Notable strings

### `CNetworkManager` (Massive ad client transport)
- `ALLOCATION Failed for CNetworkManager`
- `CNetworkManager::SetServerAddress` / `Set new address (%d) at index (%d) with host (%s).`
- `CNetworkManager(Static): New server index out of bounds (%d).`
- `CNetworkManager(Static): Can not obtain lock to server address array.`
- `NetworkManager::GetServerAddressU32` / `...GetServerPortU16` / `...GetServerHostName`
- `Cannot get Server Address because DNS is still Pending`
- `NetworkManager was already initialized` / `NetworkManager successfully intialized` / `NetworkManager intialization failed` (sic — "intialized")
- `ServerAddressArray`, `Incrementing Server Array references. It now has %d references.`
- `Connecting to %s on Port %d...`, `Server address is 0.0.0.0 for current request.`
- `BW Receive Limit: %d bytes` / `BW Send Limit: %d bytes` (bandwidth caps)
- `Heartbeat request is already pending, not creating another`, `Heartbeat wait timer has expired.`

### Massive ad network (CMassiveClientCore + HTTP)
- `CMassiveClientCore::Initialize` / `Shutdown` / `EnterZone` / `MPSessionCreate` / `MPSessionJoin` / `Tick` / `FlushImpressions`
- `MP Create Session: %s`, `Connected to Server %s`, `Singleplayer`, `Multiplayer`
- Ad-server REST endpoints: `/adsrv/4/openSession`, `/adsrv/4/closeSession`, `/adsrv/4/locateService`, `/adsrv/4/enterZone`, `/adsrv/4/exitZone`, `/impsrv/4/heartbeat`
- `Reading Massive Player ID: %d`, `Reading Massive Session ID: %d`, `Reading HMAC Signature:`
- HTTP/1.1 wrapper: `HTTP Method: POST`, `Content-Type:application/massive`, `User-Agent:%s%s`, `Adclient Massive Inc./`, `Transfer-Encoding: chunked`
- Xbox transport: `XNetServerToInAddr failed with %d.`, `Getting secure address for Server %d...`, `Found %d Massive Servers:`, `No MASSIVE SG's were returned from XTitleServerCreateEnumerator.`, `XOnlineGetServiceInfo failed with 0x%0x.`, `X360 LSP`

### Xbox 360 LIVE / System Link session (Xb360Session + GameManager)
- `Xb360Session::JoinSession failed.`
- `xb360session: UpdateState XSession call failure (%x) toState=%d,pendState=%d,failState=%d`
- `xb360session: XSessionSearchByID error %x`, `xb360session: XSessionArbitrationRegister error %x`, `... mNonce [%x] result [%d]`
- `XLSP Host lookup failed`, `XNetXnAddrToInAddr failed`, `XNetConnect failed`, `XNetGetConnectStatus returned XNET_CONNECT_STATUS_LOST`
- System Link: `Error registering LAN key!`, `Error creating LAN key!`, `Unable to register System Link Key!`
- `GM: GameManager listening on port %d`, `GM: GameManagerHostedGame::StartGame() game starting...`, `GM: GameManager Protocol Version for player %i does not match!`, `TID %i (LR=%i, GR=%i): Game not found in GameManager!`
- Dedicated-server type enums: `XBOX_360_DEDICATED_SERVER_TYPE_NONE` / `_SG` / `_UNSECURE` / `_XLSP`
- Transaction layer: `Received serviceless TXN: %s`, `canceling transaction %i due to object deletion.`, `TID %i --- timeout of Block request`, `Warning: You currently have %d simultaneous outbound transactions, but TitleParameters::GetDefaultMaxSimultaneousTransactionCount() is only %d.`
- Config keys: `RESERVE-HOST`, `SG-PORT`, `XLSP-PORT`, `XLSP-NAME`, `INT-PORT`, `FAV-PLAYER-UID`, `FAV-GAME-UID`, `activityTimeoutSecs`, `NetworkQueueIncomingLength %d`, `NetworkQueueOutgoingLength %d`

### PlayNow matchmaking config (parsed text format)
- `SessionType` and its assert: `SessionType must be one of: FindServer, AssignHost, ResetServer, or ListServers...`
- `HostSetupTimeoutSeconds` + `/* //HostSetupTimeoutSeconds is only valid for ResetServer or AssignHost session Types...`
- `/* //ListServer_* is only valid for ListServers sessionType...`, `ListServers_CountServersAvailableForReset`, `ListServers_MaxCount`
- `GameProtocolVersion`, `DebugThreshold must be one of: off, high, med, low.`
- Player pooling: `PoolPlayer_MaxPlayers`, `PoolPlayer_PlayerCountThresholds`, `PoolPlayer_PlayerFitThresholds`, `PoolPlayer_TimeoutSeconds`, `NO_POOL_TIMEOUT`
- Matchmaking preference grammar: `Filter`, `IntegerPreference`, `StringPreference`, `MatchingGameAttrib`, `MatchingOption` (`Normal`/`MatchUnusedServer`), `VotingMethod` (`Lottery`/`Plurality`), `Weight`, `Scale`, `FitThresholds`, `FitTable_My_`, `PlayNowOptionsVersion`

### Command-line / boot flags (string region ~51735)
- `-syslink`, `-coop`, `-nosecure`, `-maxkey=`, `netgamelink`, `ptdev`

### Co-op gameplay markers
- `You experienced co-op.` (achievement/stat text, line 53615) and many localized "mode coop / modalità cooperativa / modo cooperativo" strings confirm two-player co-op is the title's multiplayer mode.

## Cross-references

- `docs/mercs2-pdb-analysis/world-streaming.md` — `NetSafeLoadAssets`/`NetSafeLoadSpiel`/`NetSafeAreBriefingAssetsLoaded` tie networking to asset/world streaming.
- `docs/mercs2-pdb-analysis/pangea-engine-core.md` — `NetCommand`/`NetNotify` event channels live alongside Pangea engine event tokens.
- `docs/mercs2-pdb-analysis/physics-game.md` and `havok-physics.md` — `NetworkDamageException` and `NetSubCatNodeHealth`/`NetSubCatHealth` connect to the damage/health systems.
- Project memory: `docs/mercs2-luacd/` (decompiled Lua) and `docs/mercs2-ecs/` (ECS component registry) document the gameplay-side health/faction/inventory components that the `NetSubCat*` descriptors replicate. The store/economy defaults referenced by `ClientReimburseForSave`/`ClientRestorePreSaveCash` overlap with the support/store system map in memory.

## PC decompilation cross-reference

The functions below map this system's Xbox-build symbols to functions in the PC retail decompilation (`output/_ghidra/all_functions_decomp.txt`), via the symbol resolver in `output/jul08_prototype/pairing/resolved_networking.txt`. The resolver found **no vtable-resolved classes** for this system (the Massive/Xb360 classes never had RTTI vftables, consistent with the "no RTTI" note above), so all matches are **string-anchored** (medium confidence). Each FUN_ below was confirmed by reading its body to verify it actually references the cited string.

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| `NetworkManager::GetServerPortU16` | `FUN_009dff40` | string | accessor — locked read of a port from the server array |
| `ServerAddressArray` | `FUN_009e010a` | string | `CNetworkManager` allocator/init — builds the address array, bumps refcount |
| `SessionType` / `HostSetupTimeoutSeconds` | `FUN_009ba4b0` | string | PlayNowOptions matchmaking-config parser (high-value) |
| `SessionType` / `HostSetupTimeoutSeconds` | `FUN_009be370` | string | small config-key helper called by the parser's callers |
| `NetCategoryInfo` | `FUN_00644510` | string | category-descriptor / stream-type registration setup |
| `HostileAware` / `HostileObservers` | `FUN_005aa8f0` | string (low) | hostility/awareness query; string is data-driven, not in body |

### `FUN_009ba4b0` — PlayNowOptions matchmaking-config parser

This is the most informative match: a text parser for the `PlayNow`/`SessionType` config format documented under "Notable strings". It reads keys one by one and dispatches each parsed value through a vtable on its second argument (the options object):

```c
iVar2 = FUN_009b9410(param_1,s_SessionType_00b6594c,&local_58,0);
...
  (**(code **)(*piVar3 + 0x10))
            (piVar3,0x100,s_PlayNowOptions__InitFromString_s_00b646d8, ...,
             s_SessionType_must_be_one_of__Find_00b658f8);   // the SessionType assert
...
iVar2 = FUN_009b9410(param_1,s_GameProtocolVersion_00b658e0,&stack0xffffffa4,0);
iVar2 = FUN_009b9410(param_1,s_DebugThreshold_00b658d0,&stack0xffffffa0,0);
...
  iVar2 = FUN_009b96d0(param_1,s_HostSetupTimeoutSeconds_00b65840,&stack0xffffff9c,0);  // valid only for AssignHost/ResetServer
```

The `HostSetupTimeoutSeconds` read is gated on `unaff_EBX == 2 || == 1` — i.e. it is only consumed for two of the SessionType values, matching the Xbox-build comment "`HostSetupTimeoutSeconds is only valid for ResetServer or AssignHost`". It also parses `PoolPlayer_MaxPlayers` / `PoolPlayer_PlayerCountThresholds`, confirming the player-pooling config keys. This is the PC equivalent of `PlayNowOptions::InitFromString`.

### `FUN_009e010a` — `CNetworkManager` / ServerAddressArray construction

Allocates the manager object and the locked, reference-counted address array named by the `ServerAddressArray` string, matching "Incrementing Server Array references":

```c
pvVar1 = malloc(0xa8);                         // the manager object
...
DAT_00e75e40 = FUN_009e0b5b(s_ServerAddressArray_00b691a4);  // the named lock/array
...
_DAT_00e75e44 = _DAT_00e75e44 + 1;             // refcount bump
```

The companion accessor `FUN_009dff40` reads a port out of this array under the same `NetworkManager::GetServerPortU16` lock token and returns `0xffff` on lock-acquire failure.

### `FUN_00644510` — `NetCategoryInfo` descriptor setup

A one-shot initializer that fills a static descriptor block, installs a `CopyFromStream` vtable pointer and a `0x9e3779b9` (golden-ratio) hash seed, then stores the `NetCategoryInfo` name string — consistent with registering the networked-category type descriptor that backs the `NetPrimaryCategory` / `NetSubCat*` set:

```c
_DAT_017bebb8 = &PTR_CopyFromStream_00bc1f40;
_DAT_017bebe4 = 0x9e3779b9;
_DAT_017bebf4 = s_NetCategoryInfo_00bc56a4;
```

## Evidence & confidence

- **Inventory size:** 61 symbols in `output/jul08_prototype/inventory/networking.txt`, all in `.rdata`.
- **Distinct symbols cited from the inventory:** 49 (verified copy-exact against the inventory file).
- **Verified-by-grep against the full strings file:** all cited inventory symbols plus additional related strings (`CNetworkManager*`, `CMassiveClientCore*`, `/adsrv/4/*`, `Xb360Session`, `XSession*`, `XNet*`, `GameManager*`, `PlayNow`/`SessionType` config, `-coop`/`-syslink` flags) were confirmed present.
- **Evidence basis:** every symbol name, offset, section, and quoted string above exists in the named evidence file. The three-layer split (replication `Net*` / Massive ad-client / Xb360 LIVE matchmaking) is grounded in disjoint string clusters.
- **What is inferred:** the *behavioral* role of each group — that `NetSubCat*` enumerate replicated property categories, that `NetSafe*` are host-authoritative wrappers, that `NetClient*` are client-side mirrors, that `NetSynchImportModule`/`NetPull` do join-time state sync — is inferred from naming and string context, not from disassembled call graphs. The PlayNowOptions parser (`FUN_009ba4b0`) and the `CNetworkManager` allocator/accessor (`FUN_009e010a`/`FUN_009dff40`) are now confirmed against the PC decomp (see cross-reference).
- **Not found / unclear:** no networking source-file paths in `source_paths.txt`; no `Net*`/`Massive*`/`Xb360Session` entries in the 324-class RTTI table (class names here come from log strings, not RTTI). `Online_grant_01` purpose unclear from symbols alone.
