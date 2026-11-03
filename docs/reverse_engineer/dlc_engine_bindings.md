# Engine bindings the DLC needs that PC v1.1 lacks

The Blow It Up Again DLC's Lua was written against the PS3 title update v1.03 and the matching Xbox title
update. PS3 v1.03 (`ps3-v103-na`, `game-files/ps3-version/EBOOT_patch103.elf`) registers exactly 12 Lua bindings
over PS3 v1.00, and PC v1.1 (`pc-v11`) has none of them (`output/_exemap_exports/*.luareg.tsv`). The Xbox dev
"profile" build (`x360-preview-profile`) registers 27 more that no other image has. They are ported into the
Shipment's own ASI (`shipments/blow-it-up-again/client`), not into m2-sdk.

On PC a call to an absent binding raises a Lua error the engine swallows without a log line. The live Lua
surface of PC v1.1 (every field of every global table, read through the bridge) is
`shipments/blow-it-up-again/client/tests/data/pc-v11-lua-surface.tsv`; the client's `lua_surface` test fails while
the DLC's Lua names an engine field neither that surface nor the ASI provides.

Companion specs: [`dlc_cheats_gate.md`](dlc_cheats_gate.md) (the cheats flag, its persistence, every PS3
consumer and its PC hook point) and [`x360_profile_only_bindings.md`](x360_profile_only_bindings.md) (the 27 Xbox
dev bindings). Grades: **P** proven by disassembly or bytes, **I** inferred, **S** speculative. VAs are PS3 v1.03
unless an image is named.

## PS3 v1.03 Lua C-API (P)

`lua_checkstack` `0x8D8AB8`, `lua_pushstring` `0x8D8D88` (NULL pushes nil), `lua_pushnil` `0x8D8170`,
`lua_pushnumber` `0x8D8190`, `lua_pushboolean` `0x8D81E0`. Argument readers: `0x503AB0` string, `0x5037E8` number,
`0x505790` object (light or full userdata), `0x504A88` stores a callback `{fnref, selfref}` (function at `idx`,
optional self table at `idx+1`), `0x507AC8` calls a stored callback through `lua_pcall` (`0x8D9F38`). TOC r2 =
`0x104EFA0`.

## Net

**`Net.DLCGetMountPoint()` → string** (`0x5370B8`, P). No arguments, synchronous. Returns
`PgSysNetDownloadableContent` (`*0x115CB84`) `+0xFA3D0`, written by `0xBDB38` as `<contentRoot>/DLC/<dir>`,
normalised by `0x632508`; contentRoot comes from `cellGameDataCheckCreate2` (`0x415278`) for `BLUS30056_DLC`, and
`<dir>` from `cellFsOpendir("<root>/DLC")` (subdirectories, at most 0x80). So on PS3:
`/dev_hdd0/game/BLUS30056_DLC/USRDIR/DLC/DLC01` (I, from the SDK layout). Config flag `0x4A1F3A29` (`0x1A91109`)
makes it return `""` instead. PC port: `DLC\<level>`, the one folder under the game's `DLC` folder
(`mercs2_formats::dlc_mount`); the level's streams install there.

**`Net.GetUserName()` → string** (`0x537030`, P). Returns `*(ctx+0x3C)+0x1C7` of the online user object
(`*0x115F710`, `+0x1E8`), with no null check. The DLC calls it only from the friends leaderboard block of the
briefing, which never runs (below).

**Request and result queues** (P). Requests: 0xD0-byte messages at `0x12A48C0` under lwmutex `0x12B19F0`.
Results: 0x120-byte messages, payload at `msg+8`. Pump `PgSysNetOnline 0xE6760`, called from the PgSysNet tick
`0xF46A8` ← `0x36EDD0`. The service singleton is `0xBB47C0`; every request has a 10,000 ms timeout. No Sony NP
Score import exists (P): the backend is EA's ranking service (I, strings `RankingService`, `RecordService`).

| Message | Builder | Handler |
|---|---|---|
| 0x3D push (request) | `0xA48D0` `{name[0x3F] @+4, float @+0x44}` | `0xEE440` |
| 0x40 get-score (request) | `0xA4E48` `{name @+4}` | `0xEE0F0` |
| 0x42 get-friends (request) | `0xA4F68` `{name @+4}` | `0xEDE00` |
| 0x55 push result | `0xA4D50` `{int}` | `0xE7EA0` |
| 0x56 score result | `0xA4D68` `{int, float, name[0x3F]}` | `0xE7B90` |
| 0x57 row | `0xA4DB8` `{int a, int b, float, str[0x3F] @+0xC, str[0x3F] @+0x4C}` | `0xE8248` |
| 0x58 rows done | `0xA4E30` | `0xE8190` |

Lua callback slots, one callback each, overwritten per call (P): push `0x115F718`, score `0x115F720`,
friends/rows `0x115F728`.

**`Net.LeaderboardGetScore(board, cb[, self])`** (`0x537BA0`, P). Asynchronous. A non-string board pushes nil.
Online gates (`0x107A8`, `0x10700()+8 == 1`): when one fails it returns 0 and no callback ever fires. Calls back
`cb([self,] board, rank, score)`; score `0.0` means no entry. Then chains a 30-row query into the friends slot:
score 0 → top 30, else from `max(1, rank-15)`. DLC boards `DlcCon001`–`DlcCon004`.

**`Net.LeaderboardPushScore(board, score[, cb[, self]])`** (`0x537D98`, P). The DLC passes the player's cash
(`MrxPmc.GetCashQty()`; the long argument lists in the decompile are a multret expansion). Gated by the online gates
and by the cheats flag (`0x1C18E0()` must be 0); a failed gate returns 0 silently. Score is a float. Result
`cb([self,] int)`, the int a status (I). No validation of the board name.

**`Net.LeaderboardGetFriends(board, cb[, self])`** (`0x5379A8`, P). Like GetScore with mode friends (`0x683BB8`,
up to 90 users). Rows: `cb([self,] name, str2, a, b, score, false)`, names already seen dropped; terminator
`cb("", "", 0, 0, 0.0, true)`. No shipped Lua calls it, so `_FriendScoreReceived` (`dlc01_missionhub.lua:463`)
and the briefing's leaderboard block never run on retail (I).

PC v1.1 keeps the native leaderboard manager (row handler `0x6CBDF0`, 90-slot dedup, `addLeaderboardEntry`, no
Lua callback; request handlers `0x6CA620`/`0x6CA710`/`0x6CA7F0`) but has none of the five bindings, no Lua
callback slots and no live backend. The PC port runs over `multiplayer-restored` and `mp-server`.

## Gui

**`Gui.SetMapCorrectionOffset(x, z, scale)` / `Gui.GetMapCorrectionOffset()` → x, z, scale** (`0x522C38` /
`0x522108`, P). Three globals: `0x10556AC` x (35.0), `0x10556B0` z (40.0), `0x10556B4` scale (1.0). Set writes
nothing unless all three are numbers. PgSysGUI vtable slot 7 (`0x3D4908`) resets them to the defaults; its caller
is unread. The DLC's PDA `Init` sets `(0, 0, 1.1377778)`.

The values are consumed in native code (P), which PC has with `+35/+40` hard-coded and no scale:

| PS3 v1.03 | Use | PC v1.1 |
|---|---|---|
| `0x5DF650` minimap update | `((x+fx)*s, (z+fz)*s)` | `FUN_006201A0` |
| `0x5DE020` GPS line | `(x+p.x)*s, (z+p.z)*s` | `FUN_00620AA0` |
| `0x5DD740` radar blip | `(radius/range)*s` | `FUN_00621380` |
| `0x5DD540` co-op midpoint | `((p0+p1)*0.5 + x/z)*s` | `FUN_00621620` |
| `0x1CF868` PDA map click | `x/s − x0`, `y/s − z0` | `FUN_006A0DD0` (raw x, y) |

So the PC port is storage, the two bindings, a reset, and a hook on each of the five PC routines.

**`Gui._MarkerAddDiscDLC(guid, radius=1, r=255, g=255, b=255, f6=0)` → marker id or nil** (`0x523ED0`, P).
Identical to `_MarkerAddDisc` (`0x5241C0`) but for its creator: `0x5D4058` instead of `0x5D42A0`, which sets a
different flag field (bits 62 and 61 set, [59:58] = 2) and passes 400 instead of 100 to `FUN_003D50B0`. PC's
standard creator is `FUN_00619E90`, called by `_MarkerAddDisc` (`0x5B38C0`); its flag byte maps bit for bit onto
PS3's reversed, so the DLC byte is `(AL & 0x80) | 0x26` (I). The 100 is inlined on PC at `0x619FE3`. What the bits
and 100/400 mean is unread. PS3 v1.03's embedded Gui boot chunk adds one line PC lacks:
`_G.Marker.AddDiscDLC = Gui._MarkerAddDiscDLC`; every other embedded chunk matches PC.

## Human, Object

**`Human.SetChatterSet(obj, name)`** (`0x5300F8`, P). Hashes `name` with pandemic_hash_m2; a non-object or hash 0
pushes nil. If the object (or its template, through `FUN_0034F110`) has a ChatterSet record, sets it to the hash;
otherwise adds one. The engine reads it as asset `{hash, 0xFA0B8DBC}` (chatter), which must be loaded. PC has the
same component (descriptor `0x017BC498`, lookup `FUN_00587D80`, add `FUN_0064A570`, call sequence as in
`FUN_0065BD30`) and preloads 22 chatter sets from a table at `0x00D27548` that lacks the DLC's `Palin_Palin01`
(`0xFE96AC37`) and `Obama_Obama01` (`0xB287020B`); those ship in the DLC.
Both are chatter rows of the DLC's `resident` block. Their records name cue hashes (e.g. `0x8B57DA2A`) held by the
sounddb of `vo_resident_dlctest.<language>` (`0x1084AE93` for English), whose audio is the
`vo_stream_dlctest.<language>` wavebank; `mrxsoundbanks` requests both at level load. The DLC's wardrobe
(`dlc01_pmcinterior`, `_CompleteChangeOutfit`) calls `SetChatterSet` after `Player.SetOutfit`. Its outfit-change
line comes from `_GetPreeningVo`, which lists Mattias, Chris and Jennifer outfits only. Obama and Palin get no
line there; their voice is the character's chatter.

**`Object.GetInfiniteAmmo(obj)` → bool** (`0x544530`, P). Presence of the `CheatInfiniteAmmo` component (PC
container `0x00DF8B10`), with template fallback; a non-object pushes nil. PC's generic presence test `0x00521010`
(ESI = container, EAX = guid) runs in SecuROM VM residue.

## Pg

**`Pg.SetCheatsUsed(bool)` / `Pg.WereCheatsUsed()` → bool**: see [`dlc_cheats_gate.md`](dlc_cheats_gate.md). The
flag is a byte of the save record (PS3 R+0x4E, PC singleton+0x66), saved and loaded with it.

## Not a binding

`Object.Delete` (`dlccon004_cash.lua:98`) is registered by none of the 13 images: a fault in the shipped DLC
script, which raises on every platform.
