---
status: current
evidence: graded per row (P proven from exe / W Wally server.py only / I inferred / G gap)
---

# Mercs2 PC FESL / Theater / Messenger message catalogue (for the local-termination ASI)

Grades: **P** = read from exe code this run (decomp `mercs2_unpacked.exe_decomp.txt`, or objdump of
`securom_dump/mercs2_unpacked.exe` where Ghidra has no function); **W** = only Wally `server.py` (works in
practice); **I** = inferred; **G** = gap. "SETs/SETi" = TagField string/int setter (`FUN_00975940`/`FUN_00975800`),
"read" = `FUN_0096f800` lookup + `FUN_009cc4e0`/`FUN_009cc470`. VAs are the unpacked image.
Builders are vtable-called (`callers=[]`); each starts with `TXN=` from a name table filled at runtime
(acct `FUN_00971240`, fsys `FUN_009724c0`, asso `0x971f20`, rank `0x9732f0`, pnow `~0x983c90`).

## 0. Rules that apply to every reply (P unless marked)
- FESL reply id: client matches 24-bit tid + bit29 (doc §5). **Wally sets `0x80000000|(id&0xFF)` (server.py:460)
  — truncates tid to 8 bits; breaks after tid 255 on one connection (P mismatch).**
- FESL error: generic keys `errorCode`, `localizedMessage` (table `0xcde00c/0xcde010`),
  `errorContainer.%d.fieldName/fieldError` (`0x97158c`). Login-result UI map `FUN_006caf20`: codes 101, 102,
  103, 120, 250, −165, −221 → distinct stringdb hashes, anything else → `0xde375957` (P; meaning of each code G).
- Theater: reply frame **id = error code, 0 = OK**; TID echoed. The game's own LAN emulator sets error ids that
  are 4CCs: `'ngam'` (0x6e67616d, no such game — GDAT/EGAM) and `'jden'` (0x6a64656e, join denied + `REASON`)
  (P `FUN_0099c9b0`, `FUN_0099c9f0`, `FUN_0099efe0`, `FUN_0099cae0`).
- Values with space/comma must be quoted (doc §3). **Wally's `_quote` only escapes `=`→`%3d` (server.py:179);
  unquoted spaces truncate at the client (e.g. displayName/GDAT `N`).** (P client rule, W server)
- **Oracle:** the exe contains a LAN Theater emulator (GMLAN, LID −2) that builds GDAT/GDET/PDAT/LDAT/EGEG/KICK/GREM
  replies locally (`FUN_00996ee0`, `FUN_0099eca0`, `FUN_0099e240`, `FUN_0099ca30/0099cae0`, `FUN_0099cca0`,
  `FUN_0099ccf0`). Those are the shapes the client consumes; copy them.

## 1. FESL

### fsys
| TXN | Request fields (builder) | Reply fields the exe reads | G |
|---|---|---|---|
| Hello | `clientString, sku, locale, clientPlatform, clientVersion, SDKVersion, protocolVersion=2.0, fragmentSize`(int from TitleParameters vfn+0x30), `clientType` only if set (`0x978350`) | `theaterIp`(≤63) `theaterPort` `messengerIp` `messengerPort` `addressRemapping`(≤1023) `activityTimeoutSecs` (absent→200) `curTime`(≤31, date parse) (`FUN_00972560`). `domainPartition.*` that Wally sends is **not read here**. | P |
| MemCheck (server push, tid 0) | client replies `TXN=MemCheck result=<…>` (`FUN_00978640`) | `salt`, `type`, `memcheck.[]`, `memcheck.%d.addr`(hex) `.len` (`FUN_00972870`). First MemCheck also fires a state notify `(4,0)` on the hub when a flag is set (`0x978640`) — whether Login waits on it: **I**. Wally sends `memcheck.[]=0` after Hello and every 120 s. | P/W |
| Ping | TXN only (`FUN_009784d0`) | server Ping push (tid 0): Wally sends every 120 s; client handling G | P/W |
| Goodbye | `reason`=`GOODBYE_CLIENT_NORMAL` if code 5 else "", `message` (`FUN_00978440`) | server Goodbye: int `reason` 4→err −207, 2→−204 (`FUN_009782d0`) | P |
| GetPingSites | TXN only (`FUN_009784a0`) | `minPingSitesToPing`, `pingSite.[]`, `pingSite.%d.name/addr/type` (`FUN_00972720/780`) | P |
| Suicide, GetNextChunk, ExpireAllChunks | registered; `chunkTxn` read in `FUN_00975e30` | — | P/G |

### acct
| TXN | Request fields | Reply read | G |
|---|---|---|---|
| **Login** `0x97d5c0` | `TXN=Login`, `returnEncryptedInfo`=0/1, then **either** `encryptedInfo=<x>` (if non-empty) **or** `name=<user>` + `password=<pw>`; then `macAddr` (from hub obj +0x48) | `lkey`(≤127), `displayName`(≤31), `userId`(int64), `encryptedLoginInfo`(≤1023, cleared if absent) (`0x988fe0`); completion `0x98c020` re-reads `lkey`,`userId` only on no-error | P |
| **AddAccount** `FUN_0097d660` | `name, password, email, DOBDay, DOBMonth, DOBYear`(ints) `, zipCode, countryCode, parentalEmail`(only if non-empty) `, eaMailFlag, thirdPartyMailFlag`(0/1). No confirm-password field (UI-side). Values the PC screen supplies for email/DOB/country: **G** | reply parser not located (G); Wally has no handler → replies bare `TXN=AddAccount` (no errorCode) = success (W) | P/G |
| GetCountryList `FUN_0097d860` | TXN | `countryList.[]`, `.%d.description/ISOCode/parentalControlAgeLimit/registrationAgeLimit/allowEmailsDefaultValue` (`FUN_009714c0`, `FUN_00971740`) | P |
| GetTos `FUN_0097d890` | `countryCode` if set | `tos` (`FUN_0098bd20`) | P |
| SuggestScreenNames `FUN_0097d8e0` | `name, maxSuggestions, keywords.%d, keywords.[]` | `names.[]`, `names.%d` (`FUN_00971500/600`) | P |
| LookupUserInfo `0x97e0e0`/`0x97e2c0` | `userInfo.[]` + per item `userInfo.%i.userId` (I64) or `.userName` or `.xuid`, optional `.namespace` | `userInfo.[]`, `userInfo.%i.userName/userId/xuid/namespace` (`FUN_009718b0`, `FUN_00976d50`) | P |
| GetTelemetryToken `FUN_0097e0b0` | TXN | **no** `telemetryToken/enabled/disabled/filters` string exists in the exe → Wally's reply fields unread | P(absence) |
| GameSpyPreAuth `FUN_0097dc90` | TXN | `challenge`/`ticket` reply keys not in FESL rdata → unread; whether sent at all G | P/G |
| UpdatePassword `FUN_0097daf0` | `password, newPassword, returnEncryptedInfo` | G | P |
| SendPassword / SendAccountName / GetAccount / UpdateAccount / RegisterGame / SearchOwners | builders `0x97d820`(`name`) / `0x97d7e0`(`email`) / `0x97dba0` / `0x97dc00` / `0x97da40`(`code,game,platform,name|password|encryptedInfo`) / `0x97e030`(`screenName,searchType,retrieveUserIds,chunkSize`) | G | P |
| NuLogin / NuGetPersonas / NuLoginPersona / NuAddPersona / NuEntitleGame | **do not exist in this exe** (no `Nu*` strings) — Wally dead code (server.py:498–536) | — | P |

Login reply: Wally sends `profileId` and `entitledGameFeatureWrappers` — **neither string exists in the exe**
(unread, harmless). Wally never checks `password` and auto-creates on Login (server.py:499–500) (W).

### subs / rank / pnow / asso
| TXN | Request | Reply read | G |
|---|---|---|---|
| subs GetEntitlementByBundle `FUN_0097aaf0` | `bundleId` | `type, name, description, entitlementStatus, entitlementStatusDesc(≤15), entitlementSuspendDate, pricingOptionId` (`FUN_009739a0`, consumed by game `0x846cc9`). Wally matches exactly. | P/W |
| rank UpdateStats `0x97fee0` | `u.[]`, `u.%d.o`(I64 owner), `u.%d.ot`, stats via `FUN_0097e6c0`: `u.%d.s.[]`, `.ut .k .v(%.4f) .t .pt` | G (Wally replies TXN only) | P |
| rank GetRankedStats `0x9802a0` | `owner`(I64) and `ownerType` **only when the caller names an owner** (`test edi,edi` @0x9802d1; the game's own-stats request has neither), then `periodId, periodPast`, `keys.%d`/`keys.[]` (+`rankOrders` via `FUN_0097a3a0`) | `stats.[]`, `stats.%d.key/value/text/rank` (`FUN_009735c0`…`FUN_009733e0`) — matches Wally | P |
| pnow Start `0x984bdc` | `partition.partition`, `version`, `players.[]`, `players.0.ownerId/ownerType`, `players.%i.props.{name}`, `players.0.props.{debugHostAssignment}`, `{poolMaxPlayers}`, `{poolTimeout}`, `{availableServerCount}`, `{maxListServersResult}`, `{hostSetupTimeout}`, `{filter-*}/{filterToGame-*}`, `{pref-*}` | `id.id`(I64), `id.partition` (`FUN_0097fa50`) | P |
| ↳ ASI filter policy | each `{filter-<n>}` is matched against the listed games' `B-U-*`, `B-version`, `name`, `max_players`, `players`, `joinable` (J letter) under a key normalisation (lowercase; drop `{}`; drop one leading `b-`/`b_` then one `u-`/`u_`; drop `-`/`_`) with case-insensitive values (numeric when both parse); target = `{filterToGame-<n>}` or `<n>` when absent; a filter naming no property is logged INFO and counts as matching (user decision; `client/src/fesl.rs` `filter_outcome`) | — | policy |
| pnow **Status (server push)** | — | `props.{*}` map (all keys), `id.id`, `id.partition`, `sessionState` ∈ NEW/ACTIVE/COMPLETE/ERROR/CANCELLED/DELETED (`0x97fb10`, values 0–5); `updateType`(=="debug"), `debugTrace` (`FUN_0097fd10`). Consumer (P, disassembly `0x9bb8e3`–`0x9bbc9c`, `FUN_009b82c0`, `FUN_009b5690`): COMPLETE reads `props.{resultType}` ∈ NOMATCH/NOSERVER/JOIN/LIST/CREATE/CREATE_PROXY (table `0xcdec00`ff.); for JOIN/LIST it reads `props.{games}.[]` and per game `props.{games}.<i>.lid` / `.gid` (`"%s.%i.%s"`, keys `lid`/`gid` at `0xb64318`/`0xb64314`) and fetches each with Theater GDAT LID+GID; ERROR reads `props.{reasonString}`; `.[]` < 1 reads `props.{availableServerCount}`. Wally's `props.{games}.<i>=<gid>` shape leaves lid/gid 0 (his GID=0 GDAT workaround). | P |
| pnow Update / GetStatus | registered (`0x983cb8/0x983cc6`) | G | P/G |
| asso AddAssociations `0x981cd0` | `domainPartition.domain/subDomain/key`, `type`, `addRequests.[]`, `addRequests.%d.owner.*/member.*/mutual` | `type`, `result.[]`, `result.%d.owner./member./listSize/outcome/mutual` (`FUN_00981f10`) | P |
| asso DeleteAssociations `0x981d60` | same with `deleteRequests` | same parser | P |
| asso GetAssociations `0x981df0` | domainPartition.*, `type`, `owner.*` | `type`, `maxListSize`, `members.[]`, `members.%d.*` (`FUN_00982220`) | P |
| asso GetAssociationCount `0x981e80` | same as Get | `maxListSize`,`count` (`FUN_00972000`) I | P/I |
| asso **NotifyAssociationUpdate (push)** | — | `type`, `listSize`, `mutual`, `operation` ∈ `add`/`del`, owner/member blocks (`FUN_009823f0`) | P |

Wally implements no asso at all (W); whether the PC UI ever issues asso: G.

## 2. Theater (plain TCP; 4CC set registered in `FUN_00973b50`)
All client requests carry `TID` (appended). Frame id is `0x40000000` or `0` by a per-send flag (encoder `0x970600`, `multiplayer_rewrite_re.md` §5); UGAM is sent with `0` (live). Registered 4CCs (P): CONN USER RLST RDAT LLST
LDAT GLST GDAT GDET PDAT CGAM UGAM UGDE UPLA UBRA EGAM EGEG ECNL EGRQ EGRS QLEN PENT PLVT RGAM PING HOMG HMRQ KICK GREM
KGAM ABUS DISC RESV KEEP HGAM GRST RCLM PCNT HLST HACK HXFR HTSN HTRS HTFN RSRQ RSCL QENT QLVT DQEG QKCK UQUE.

| 4CC | Client request (builder) | Reply / push fields the exe reads | G |
|---|---|---|---|
| CONN | `PROT=2, PROD, VERS, PLAT`(if set)`, LOCALE, SDKVERSION` (`FUN_0097adb0`) | only `activityTimeoutSecs` (×1000 → Theater timeout), then client immediately sends USER (`FUN_009b5380`). Wally's `TIME`,`PROT` unread. | P |
| USER | `CID, MAC, SKU, LKEY, NAME` (`FUN_0097ae60`) | handler `0x9b20e0` checks error only, reads **no keys** (Wally's `NAME` unread) | P |
| LLST | `FILTER-FAV-ONLY/NOT-FULL/NOT-PRIVATE/NOT-CLOSED/MIN-SIZE`, `FILTER-ATTR-U-*`, `FAV-PLAYER/GAME(-UID)` (`FUN_0097aee0`) | reply `NUM-LOBBIES`, then **N × LDAT** frames: `LID, NAME, PASSING, FAVORITE-GAMES, FAVORITE-PLAYERS, LOCALE, MAX-GAMES, NUM-GAMES` (`FUN_009b1d30`); LAN shape `FUN_0099e240` | P |
| GLST | `LID, TYPE`(G/P)`, FILTER-*`, `FAV-*`, `GID`(>0)`, COUNT` (`FUN_00980810`) | reply `LID, NUM-GAMES, LOBBY-MAX-GAMES, LOBBY-NUM-GAMES` (`FUN_009b1dd0`) then per-game GDAT (LAN `FUN_009a8f00`). **Wally has no GLST** (lists via pnow). | P/W |
| GDAT | 3 forms: `LID+GID` (`FUN_0097afd0`); `USER`+`TYPE` (`FUN_00980960`); `UID`(I64)+`TYPE` (`FUN_009809d0`) | GDAT: `LID, GID, N, TYPE(G|P), MP, AP, JP, B-maxObservers, B-numObservers, HN, HU`(I64)`, B-version, J`(O/W/C) + `B-U-*`; then **GDET** `LID, GID, UGID, D-*`; then per player **PDAT** `LID, GID, PID, NAME, UID, P-*` (LAN `FUN_00996ee0`/`FUN_0099eca0`; GDET parse `FUN_00974000`). Not-found → id `'ngam'`. GDAT field consumers are a generic attr map: G. Wally adds `I P PL V PW QP INT-IP INT-PORT`. | P/W |
| CGAM | doc list (`FUN_00980a60`): `LID RESERVE-HOST NAME PORT HTTYPE TYPE QLEN DISABLE-AUTO-DEQUEUE HXFR INT-IP INT-PORT MAX-PLAYERS B-maxObservers B-numObservers PASSWORD? UGID SECRET B-U-* B-version RESERVE-IDS RESERVE-TIMEOUT JOIN RT` | `MAX-PLAYERS`, `SECRET`(≤127), `UGID`(≤36), `JOIN`(≤9), `EKEY`(**≤16**) (`FUN_0097b9b0`); LAN reply also `LID, GID, QLEN` (`FUN_009aa020`). Wally EKEY is 24 chars → both sides truncate to the same 16 (P). | P |
| UGAM | `LID GID JOIN MAX-PLAYERS B-maxObservers B-numObservers` (`FUN_0097b070`) or `LID GID NAME B-U-* JOIN RT` (`FUN_0097b100`) | G — Wally sends **no reply** (server.py:856) and games work | P/W |
| UGDE / UPLA / UBRA | `LID GID D-*` / `LID GID PID HMO P-*` / `LID GID START` | G; Wally replies TID only to UBRA | P/W |
| EGAM | client: common builder `0x980ed0` (disassembled; not in the decomp): `R-U-*`, `PORT`, `R-INT-PORT`, `R-INT-IP` (local address), `GROUP.[]`/`GROUP.%i`, `R-GROUPID`, `PTYPE` (`P`/`O`); then either `GID` (with `LID`), or the join-by-player builder `0x981080`: `USER`, `R-USER` (the player), `TYPE` (`G`/`P`). Live 2026-10-11: joining a friend sends the `USER` form after `acct LookupUserInfo`. `TID` appended (P) | reply `LID, GID, TID` (LAN `FUN_0099efe0`); errors `'ngam'` / `'jden'`+`REASON` (`f`/`c`). The LAN dispatcher handles the EGAM result and EGEG as two separate messages (`0x9aac75` / `0x9aac97`): EGAM answers the server-side checks, EGEG carries the host's decision. | P/W/G |
| **EGRQ (push → host)** | — | `NAME UID PID TICKET IP PORT R-INT-IP R-INT-PORT XUID R-XUID R-UID R-USER R-U-* GROUP.[] R-GROUPID PTYPE` (`FUN_0097c000`); LAN `FUN_009aa140` assigns the joiner's PID here (per-game counter) and sends `TICKET` as `0x%x`, PTYPE `P`/`O` | P |
| EGRS | `LID GID ALLOWED PID` + `REASON` if denied, written `%d` (`FUN_0097b380`; host gate `FUN_0098fc80` reasons 2/6/7 — `multiplayer_rewrite_re.md` §10) | reply TID only (W) | P/W |
| **EGEG (push → joiner)** | — | `LID GID PID TICKET`(string ≤127)` UGID EKEY`(≤16)` REASON` (`FUN_00981490`: `c/f/h/q/r/t` or `%d` into one int; no `w`; meanings in `multiplayer_rewrite_re.md` §10) + `HUID I PL P INT-IP INT-PORT` (`FUN_0097c420`; `PL` compared to `xbox`/`xbox360` only; LAN sends `PC`) | P |
| ECNL | `LID GID` (`FUN_0097b340`) | G | P |
| PENT / PLVT | `LID GID PID` (+`P-*` for PENT) (`FUN_0097b420`/`FUN_0097b4d0`) | PENT reply `TID`/`ID` + `PID` (LAN `FUN_0099cc60`); PLVT reply `TID`/`ID` (LAN `FUN_009a10a0`) | P |
| RGAM | `LID GID` (`FUN_0097b530`) | G | P |
| KICK / GREM (push) | — | `LID GID PID` / `LID GID` (LAN `FUN_0099cca0`/`FUN_0099ccf0`) | P |
| QENT/QLEN (push) | — | `REASON`(c/f/h/q/r/t/w or int), `QPOS`, `QLEN` (`FUN_00974090`) | P |
| HTSN/HTFN/HXFR (host migration) | `LID GID HPID` etc. (`FUN_009812c0`…`FUN_009813d0`) | `HPID SECRET UGID` (`FUN_00974220`); `NGID HKEEP` | P |
| PING | `FUN_0097ad90` (no fields) | the exe's LAN Theater emulator treats a client PING as a no-op (`FUN_009ab370` is that emulator's request dispatcher, not the client receive path). Server PING push (id 0): the client **answers** with a PING frame of id 0 (no request bit). Live, 2026-10-11 `multiplayer_restored.log`: 60 s keepalive push, then the client's id-0 PING; answer payload `TID=0` (live 2026-10-11) | P (live) |

## 3. Messenger (plain TCP 13505; 4CCs `FUN_00972e40`)
4CCs (P): AUTH DISC USCH USER PADD PDEL PSET PGET RADD RADM RRSP RDEL RDEM RNOT RGET ROST MLST TCKL GINV GRSP GRVK GNOT
SEND RECV BRDC EPST EPGT ADMN PING.

| 4CC | Request | Reply/push read |
|---|---|---|
| AUTH | `LKEY PROD VERS PRES RSRC` (`FUN_00979320`) or `USER PASS PROD VERS PRES RSRC` (`FUN_009793a0`) | G |
| RGET / RADD / RDEL / RRSP | `LIST GROUP LRSC PRES PEND` / `LIST USER GROUP LRSC PRES ATTR RPLC` / … (`FUN_00979b10`, `FUN_00979710`, `FUN_009799b0`, `FUN_00979850`) | roster item `USER UID DOMN RSRC GROUP ATTR` (`FUN_009c25f0`); change `USER UID GROUP CHNG ATTR` (`FUN_009c24a0`) |
| PSET/PGET presence | builder not located (G) | `USER DOMN RSRC SHOW STAT PROD SESS TITL TIID EXTR ATTR RICH`; SHOW ∈ DISC/CHAT/AWAY/XA/DND/GAME (`FUN_009c21d0`, `FUN_009c23f0`) |
| GINV / GRSP / GRVK | `USER SESS TITL RSRC GSTR` (`FUN_0097f1c0`) / `USER ANSW RSRC` / `USER SESS RSRC` | invite `HOST USER TYPE SESS TIID GSTR` (`FUN_009c2790`) |
| SEND / RECV | `TYPE USER SUBJ BODY SECS` (`FUN_00979cd0`) | `TYPE USER DOMN RSRC TIME SUBJ BODY NOREPLY` (`FUN_009c28d0`) |
| ADMN (push) | — | `BOOT GAG UNGAG DUPL` (`FUN_009c29d0`) |
| EPGT / PING / DISC | TXN-less 4CCs (`FUN_009792c0/e0/a0`) | G |

**Is Messenger needed?** Wally advertises 13505 with no listener (server.py:24) and host/join work → not needed
for play (W). Friends/presence/game-invites have two parsers: FESL asso (list ops) and Messenger roster/presence/
GINV (P). Which the PC friends UI (`Net.EnterFriendsLobby`, `joinFriendsGame`) actually drives: **G** — next step
is xref of `FUN_00979b10`/`FUN_0097f1c0` callers from the Lua binding.

## 4. Flow and which replies are load-bearing
Order (W, `docs/reverse_engineer/networking_code_map.md` §6.2 + server.py; client-side steps P where cited):
1. FESL TLS connect → `fsys Hello` → reply (Theater/Messenger addresses, timeout) → server push `MemCheck` → client
   `MemCheck result`.
2. (create path) GetCountryList/GetTos/AddAccount → `acct Login` → reply `lkey, displayName, userId`.
3. GetPingSites, `subs GetEntitlementByBundle`, `rank GetRankedStats`, GetTelemetryToken (W order).
4. Theater connect → `CONN` → reply (client then auto-sends `USER` with `LKEY`, P `FUN_009b5380`) → `USER` reply.
5. Browse: `pnow Start` → reply `id.id/id.partition` → push `pnow Status` (`sessionState=COMPLETE`, `props.{games}`)
   → `GDAT` per game (→ GDAT+GDET+PDAT). (`LLST`/`GLST` path exists, P; Wally answers LLST only.)
6. Host: `CGAM` → reply (EKEY/SECRET/UGID) → **host self-entry**: the host sends `EGAM` for its own game
   (live 2026-10-11, 3 ms after the CGAM reply, when a logged-in player continues the campaign; fields as sent:
   `PORT R-INT-PORT R-INT-IP PTYPE=P LID GID TID`) → reply
   `TID LID GID` → push `EGRQ` to the host for its own PID (`LID GID NAME UID PID TICKET PTYPE`, no address)
   → host `EGRS` → reply `TID` → push `EGEG` (`LID GID PID TICKET UGID EKEY`, no address, sent whatever
   `ALLOWED` says). P: the LAN emulator's own-game branches `FUN_009ab0e0` (→ `FUN_0099c8d0`/`FUN_00990c60`/
   `FUN_009aa140`) and `FUN_009a0e80` (requester is this machine → `FUN_0099ca30`, `UGID=NOGUID`,
   `EKEY=NOENCYRPTIONKEY`). The host then sends `PENT` for its own PID (live, 25 ms after the EGEG); the LAN
   PENT handler `FUN_0099cc60` only echoes `TID` (`ID`) `PID`. Then `UBRA/UGAM/UPLA` updates.
7. Join: joiner `EGAM` → reply; server push `EGRQ` → host; host `EGRS` → reply; server push `EGEG` → joiner; host
   `PENT` (reply `PID`); leave `PLVT`/`ECNL`; host close `RGAM`.

Mandatory (I unless noted): Hello reply (Theater address source, P), Login reply with `lkey` (USER sends it, P),
CONN reply (gates USER, P), USER reply (P: success check), CGAM reply (EKEY/UGID), EGAM reply, EGRQ/EGEG pushes,
pnow Start reply + Status push (browse), GDAT. Ignorable in practice (W, Wally sends none): UGAM, PLVT, fsys
Ping/Goodbye/MemCheck replies, all Messenger. The SDK transaction layer has per-TID timeouts ("TID %i --- timeout
of Block/Nonblock request", strings `0xb606d0`/`0xb606f8`; which service/TXNs use it: I), so an unanswered
*blocking* request presumably fails its step (I).

## 5. Wally vs exe — explicit disagreements
| # | Item | Wally | Exe | Grade |
|---|---|---|---|---|
| 1 | Login TXN names | handles `NuLogin`, `NuLoginPersona`, `NuGetPersonas`, … | only `Login`; no `Nu*` strings | P |
| 2 | Login request | reads `name` only | sends `name`+`password` **or** `encryptedInfo`, + `returnEncryptedInfo`, `macAddr` | P |
| 3 | Login reply | `displayName userId profileId lkey entitledGameFeatureWrappers` | reads `lkey displayName userId encryptedLoginInfo`; `profileId`/`entitled…` absent from exe | P |
| 4 | FESL reply id | `0x80000000\|(id&0xFF)` | 24-bit tid match | P |
| 5 | Quoting | only `=`→`%3d`; spaces unquoted | value stops at space unless `"…"` | P |
| 6 | AddAccount/GetTos/GetCountryList/SuggestScreenNames | unhandled → bare `TXN=` echo | parsers expect `tos`, `countryList.*`, `names.*` | P |
| 7 | Hello reply | sends `domainPartition.*` | Hello parser does not read it | P |
| 8 | CONN reply | `TIME, activityTimeoutSecs=86400, PROT` | reads only `activityTimeoutSecs` | P |
| 9 | USER reply | `NAME` | reads no keys | P |
| 10 | GLST | not handled | builder + reply parser exist | P |
| 11 | EGEG `PL` | `pc` | compares `xbox`/`xbox360`; LAN sends `PC` | P |
| 12 | EKEY | 24-char base64 | read into 16-char buffer (both CGAM and EGEG) | P |
| 13 | GetTelemetryToken / GameSpyPreAuth replies | token/challenge/ticket | no consumer strings | P |
| 14 | Messenger / asso | absent | full builders + parsers present | P |

Gaps to close next: AddAccount reply parser and the PC create-account screen's email/DOB/country values; EGAM
builder (expected `GID|USER, PORT, R-INT-IP, R-INT-PORT, PTYPE`); PSET builder; which Theater/FESL requests are
blocking; friends-UI path (asso vs Messenger); meaning of error codes 101/102/103/120/250/−165/−221 (resolve the
stringdb hashes in `FUN_006caf20`).
