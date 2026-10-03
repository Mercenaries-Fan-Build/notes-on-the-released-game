# mercs2-luacd-xbox — Phase A: Xbox 360 base-game Lua decompilation

Decompiled source of the Mercenaries 2 **Xbox 360** retail `scripts_vz` chunk, parallel to the
PC corpus at `docs/mercs2-luacd/src/vz/`. 114 files, one per input, matching PC names
exactly except for the obfuscated master-script (PC `xQ!L.luac` → kept here as `#mO.lua`,
the Xbox counterpart's original name).

## Tooling

- **Decompiler:** `tools/external/unluac/unluac.jar` (v1.2.3.569)
- **JVM:** bundled `tools/jdk21/jdk-21.0.11+10/bin/java.exe` (OpenJDK Temurin 21.0.11+10 LTS)
- **No byteswap needed.** unluac reads the Lua 5.1 header and switches endianness itself.

## Invocation

For every `*.luac` under
`output/analysis/cross_platform/scripts_vz_comparison/Xbox 360/bytecode/`:

```
java -jar tools/external/unluac/unluac.jar <in.luac> > docs/mercs2-luacd-xbox/src/vz/<name>.lua
```

Driver: `scratchpad/decomp_x360.sh` (iterates all 114 inputs, captures stderr per file,
writes a results TSV). Runtime: ~2 min on this box, all serial.

## BE handling — evidence

Header of `wifmissionflow.luac` (xxd first 10 bytes):

```
1b 4c 75 61 51 00 00 04 04 04 04
   L  u  a  Q  official endian=0 int=4 size_t=4 instr=4 lua_Number=4
```

- `\x1BLuaQ` = Lua 5.1 bytecode.
- Endian flag byte 6 = **0 → big-endian** (PC file is 1 → little-endian).
- `lua_Number` size byte 10 = **4** (single-precision float).

**Correction (Phase B):** this file originally claimed "PC uses 8 (double)". That is wrong —
Mercs 2's PC retail Lua bytecode also uses `lua_Number = 4` (single-precision float). Measured
across all 240 `scripts_resident_comparison/PC Retail/bytecode/*.luac`, every PC header is
`1b 4c 75 61 51 00 01 04 04 04 04 00` (byte 10 = `04`). The *only* delta between PC and Xbox
headers is byte 6 (endian flag).

unluac handles both the BE flag and the 32-bit float representation directly; no pre-swap or
header-rewrite was required. Exit 0 and non-empty, well-formed Lua on all 114 inputs
confirms it.

## Output quality note

The Xbox bytecode is stripped of debug info (no local names, no line numbers). unluac therefore
emits **register-level pseudocode** — statements of the form

```
L0_1 = inherit
L1_1 = "MrxMissionFlow"
L0_1(L1_1)
```

in place of the PC decomp's `inherit("MrxMissionFlow")`. This is semantics-preserving,
syntactically valid Lua, and sufficient for the downstream per-system behavioural diff: every
string literal, every call target, and every branch structure is intact. Sanity-checked by
string-pool spot-grep (e.g. `"MrxCinematic"` appears exactly once in both X360 and PC
`wifmissionflow.lua`).

The PC corpus benefits from debug info — do not expect line-for-line textual parity between the
two trees; expect **behavioural** parity (ordered calls, string tables, table shapes).

## Result — 114 ok / 0 fail

Total decompiled source: **2 411 925 bytes** across 114 files. No stderr output on any run.

### Spot-check — 5-line heads from three files

**`wifbios.lua`**
```lua
local L0_1, L1_1

function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = 0
```

**`oilcon005.lua`**
```lua
local L0_1, L1_1
L0_1 = inherit
L1_1 = "MrxTaskContract"
L0_1(L1_1)
L0_1 = import
```

**`wifvzboundary.lua`**
```lua
local L0_1, L1_1
L0_1 = import
L1_1 = "MrxCheatBootstrap"
L0_1(L1_1)
L0_1 = import
```

### Per-file results

Compact table, `name  status  bytes`:

```
#mO                              ok      52875
allcon001                        ok      19387
allcon002                        ok      64973
allcon003                        ok       7395
allcon008                        ok      10913
allcon050                        ok       1284
allcon052                        ok       1038
allcon053                        ok       1037
alljob002                        ok       6267
alljob003                        ok        448
alljob020                        ok      11756
chicon001                        ok      16969
chicon002                        ok      28558
chicon003                        ok       9306
chicon008                        ok      13023
chicon009                        ok      16291
chicon050                        ok       1037
chicon051                        ok       1284
chicon053                        ok       1246
chijob002                        ok       5040
chijob003                        ok        449
chijob020                        ok       5148
gurcon001                        ok      27783
gurcon002                        ok      53021
gurcon003                        ok      34944
gurcon005                        ok       3316
gurcon050                        ok        773
gurcon052                        ok        835
gurcon053                        ok       2671
gurjob001                        ok       1047
gurjob002                        ok       2715
gurjob006                        ok        445
gurjob020                        ok       8200
jetcon001                        ok      26040
meccon001                        ok      44601
mecjob                           ok      18838
mecjob001                        ok        957
mecjob002                        ok        596
mecjob003                        ok       1267
oilcon001                        ok     121828
oilcon002                        ok      88676
oilcon003                        ok      27575
oilcon005                        ok      11178
oilcon020                        ok      51855
oilcon021                        ok      34619
oilcon050                        ok       2414
oilcon051                        ok        817
oilcon052                        ok        817
oiljob004                        ok        451
oiljob008                        ok       6547
oiljob011                        ok       4686
pircon001                        ok      13889
pircon002                        ok      28434
pircon003                        ok      42889
pircon004                        ok      50223
pircon051                        ok        835
pircon052                        ok        835
pirjob001                        ok        445
pirjob012                        ok       4211
pirjob020                        ok       5577
pmccon001                        ok      44016
pmccon002                        ok      18343
pmccon003                        ok      54243
pmccon004                        ok      32913
pmccon013                        ok      11462
pmccon015                        ok       8109
pmccon016                        ok      11146
pmccon018                        ok      49320
pmccon031                        ok      60589
pmccon032                        ok      47524
pmccon033                        ok      52653
pmccon034                        ok      44073
pmcjob001                        ok        801
stagingact1                      ok       6889
vzacon001                        ok      64752
wifbios                          ok       4325
wifbriefingdata                  ok     477103
wifcheatstockpile                ok      12164
wifequipmentdata                 ok       7222
wiffreeplay                      ok       3498
wifhints                         ok      11548
wifhqdata                        ok      18937
wifmissiondata                   ok      38899
wifmissionflow                   ok      92808
wifpmcgarage                     ok      37432
wifpmcinterior                   ok     103094
wifrecommendationdata            ok       6338
wifstarterdata                   ok      25891
wiftutorialairstrikeinterrupt    ok       2244
wiftutorialalarm                 ok        572
wiftutorialallieshonk            ok       3841
wiftutorialapc                   ok       1273
wiftutorialboat                  ok       1276
wiftutorialc4                    ok       2770
wiftutorialc4switch              ok       1270
wiftutorialcollateraldamage      ok        958
wiftutorialcollectibles          ok       3991
wiftutorialcooprevive            ok        576
wiftutorialcooptether            ok        572
wiftutorialgatehonk              ok       1445
wiftutorialhelicopter            ok       1294
wiftutorialhelirepairpad         ok       1132
wiftutoriallowfuel               ok        573
wiftutorialnofuel                ok        572
wiftutorialswimming              ok       1651
wiftutorialtank                  ok       1284
wiftutorialtankhijack            ok       2483
wiftutorialtrespass              ok        959
wiftutorialvehicledisguise       ok       5430
wiftutorialwheeledvehiclebasic   ok       2163
wifvzambience                    ok       1644
wifvzatmosphere                  ok       3899
wifvzboundary                    ok      11362
wifvzregionnames                 ok       8025
```

No failures. Scratchpad run artefacts (per-file stderr dir and results TSV) are under
the session scratchpad and may be discarded.

## Naming — `#mO.lua`

Kept the original obfuscated filename (same convention as PC's `xQ!L.lua`). The two files share
one and the same intent — the Xbox-side vz master-script — but have different literal names in
their respective WADs. Unlike PC's `xQ!L.luac`, the Xbox `#mO.luac` is a *plain* Lua 5.1 bytecode
chunk, not an obfuscated runtime-patching blob; it decompiled to 2 279 lines of standard
register-level pseudocode without any special handling.

---

# Phase B — resident + shell + PC backfill

Extends Phase A with the Xbox 360 **resident** and **shell** Lua chunks (previously undecompiled),
and backfills twelve `.lua` files the existing PC decomp at `docs/mercs2-luacd/src/resident/` was
missing.

## Scope

| Batch | Source bytecode dir | Output dir | Count |
|---|---|---|---|
| X360 resident | `output/analysis/cross_platform/scripts_resident_comparison/Xbox 360/bytecode/` | `docs/mercs2-luacd-xbox/src/resident/` | **238 / 238 ok** |
| X360 shell    | `output/analysis/cross_platform/scripts_shell_comparison/Xbox 360/bytecode/`    | `docs/mercs2-luacd-xbox/src/shell/`    | **26 / 26 ok**  |
| PC backfill   | `output/analysis/cross_platform/scripts_resident_comparison/PC Retail/bytecode/`| `docs/mercs2-luacd/src/resident/`      | **12 / 12 ok**  |

Totals: Xbox resident 3 538 034 bytes, Xbox shell 471 994 bytes.
PC resident decomp now at **240 / 240** (full parity with the PC bytecode listing).

Driver: `scratchpad/decomp_phase_b.py` (parallel, 8 workers; ~21 s wall-clock).
Invocation identical to Phase A — `java -jar unluac.jar <in.luac>` to stdout.
No stderr output on any run; no NTFS-illegal filenames in either tree.

## Platform parity

Comparing basenames across the two 240-file resident bytecode listings:

- **PC-only (not shipped on Xbox):** `mrxguiltiprecache`, `mrxguiltiprecachelayout` — exactly two,
  as expected.
- **Xbox-only (not shipped on PC):** *(none)*.

So the Xbox resident corpus is a strict subset of the PC resident corpus by name, minus the two
`mrxguiltiprecache*` modules.

## PC backfill — the twelve

All twelve are *empty-chunk stubs*: the compiled `.luac` body is a bare `return` (no locals,
no literals, no body), 76–81 bytes each (12-byte Lua header + source name + minimal `Proto` +
WAD-chunk `CSUM` trailer). unluac exits 0 and emits **zero bytes** — this is the correct
decompilation of a `return`-only chunk, not a decompiler failure (`--disassemble` confirms the
single-instruction body `return r0 1`). The Xbox counterparts (also stubs, but with debug info
stripped) emit `local L0_1, L1_1
` because unluac's maxstacksize heuristic kicks in without
`.source` metadata — a format artefact, not real content.

For the PC backfill we write a short sentinel comment (203 bytes) explicitly flagging the chunk
as empty, so the files exist, grep cleanly, and preserve the invariant "every `.luac` in the PC
resident bytecode listing has a sibling `.lua` in the decomp tree".

Backfill names:

```
all_debug
all_gui
all_hijack
all_humans
all_objectscript
all_preload
all_sound
all_testscript
all_vehicles
all_weapons
common_asset
healthpickup
```

Hard rule honoured: the driver skips any output path that already exists under
`docs/mercs2-luacd/src/`, so no PC decomp file was overwritten. Phase A's `vz/` and `shell/`
canonical PC trees were not touched.

## Result — 276 ok / 0 fail

Of 276 Xbox-side decomps (238 resident + 26 shell + 12 PC backfill): all succeed; no stderr
output on any run.

### Spot-check — 5-line heads

**`src/resident/airplane.lua`**
```lua
local L0_1, L1_1, L2_1, L3_1
L0_1 = inherit
L1_1 = "VehicleBlippable"
L0_1(L1_1)
L0_1 = {}
```

**`src/resident/airstrike_atomsphere_bombrun.lua`**
```lua
local L0_1, L1_1

function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
```

**`src/shell/mrxgui.lua`**
```lua
local L0_1, L1_1
L0_1 = import
L1_1 = "MrxGuiBase"
L0_1(L1_1)
L0_1 = import
```

### Per-file results

Compact table, `name  status  bytes`:

```

### resident (238 files)
Init                             ok       1215
Multi                            ok       2150
airplane                         ok        505
airstrike_atomsphere_bombrun     ok       4278
airstrike_atomsphere_carpetbomb  ok       4007
airstrike_atomsphere_clusterbomb ok       4260
airstrike_atomsphere_daisycutter ok       4397
airstrike_atomsphere_fuelairbomb ok       4381
airstrike_atomsphere_moab        ok       4395
airstrike_atomsphere_tactnuke    ok       4376
alarm                            ok      12504
all_debug                        ok         18
all_gui                          ok         18
all_hijack                       ok         18
all_humans                       ok         18
all_objectscript                 ok         18
all_preload                      ok         18
all_sound                        ok         18
all_testscript                   ok         18
all_vehicles                     ok         18
all_weapons                      ok         18
antiair                          ok      18481
autogunship                      ok       7038
barbell                          ok        183
beacon                           ok       1199
bench                            ok        501
binoculars                       ok         66
blippable                        ok       6646
bountycopter                     ok       3042
collectable                      ok       2249
common_asset                     ok         18
crate                            ok       2925
danceradio                       ok       4157
dangerousbuilding                ok      22946
despawner                        ok         66
dropoff                          ok       5132
emplaced                         ok       3908
enemyblippable                   ok       6273
factionzone                      ok       4807
foodcart                         ok         66
fountain                         ok        374
friendlygate                     ok      14339
fueltank                         ok       1403
gamebootstrap                    ok       4754
goal                             ok       2581
gurpodium                        ok       5614
hackybench                       ok        110
healthpickup                     ok         18
heavymg                          ok        831
helicopter                       ok       1148
hero                             ok      20969
hijackcontractmanager            ok        407
homingmissile                    ok       1937
inheritable                      ok       1588
islandfortress                   ok       5496
jammer                           ok       5462
laptop                           ok       5668
levelbootstrap                   ok        940
lifestyle_oillif001_table        ok        948
livingworldprop                  ok        211
materialanimation_largecanopy01  ok        907
materialanimation_largecanopy02  ok        898
materialanimation_treeplaza02    ok        890
mine                             ok       4187
monument                         ok         66
moonpatrol                       ok       8239
mrxachievements                  ok      18019
mrxactionhijack                  ok      90351
mrxai                            ok       2509
mrxapcdrop                       ok       7024
mrxartillery                     ok       5865
mrxartilleryattack               ok       2852
mrxboatdelivery                  ok        827
mrxbombingrun                    ok       4299
mrxbootstrap                     ok       7046
mrxbriefing                      ok     169123
mrxbunkerbuster                  ok       8383
mrxcarpetbomb                    ok       5025
mrxcheatbootstrap                ok      22313
mrxchicon001rescue               ok       7149
mrxcinematic                     ok       1180
mrxclusterbomb                   ok       5528
mrxcombatairpatrol               ok       5764
mrxcoop                          ok       8887
mrxcopterdrop                    ok       5476
mrxcratedelivery                 ok       1124
mrxcruisemissile                 ok       6346
mrxdaisycutter                   ok       4988
mrxfactionmanager                ok      80189
mrxfollow                        ok      13442
mrxfuelairbomb                   ok       8904
mrxgui                           ok      23112
mrxguiattractlayout              ok       2162
mrxguiattractmode                ok       4616
mrxguibase                       ok     123799
mrxguibinoculars                 ok      16775
mrxguibootstrap                  ok       2173
mrxguicinematic                  ok      29171
mrxguicinematiclayout            ok       5359
mrxguidialogbox                  ok      62457
mrxguigarage                     ok      12004
mrxguihudactionhijack            ok      24618
mrxguihudammocountersnew         ok      39110
mrxguihuddamageindicator         ok       5848
mrxguihudfactionbuffer           ok      16619
mrxguihudfactiongauge            ok      42617
mrxguihudhealthcounter           ok      28239
mrxguihudmelee                   ok       4776
mrxguihudmessage                 ok      70672
mrxguihudobjectivetray           ok      11738
mrxguihudradar                   ok      17710
mrxguihudresourcecounter         ok      30728
mrxguihudreticle                 ok      36797
mrxguihudsupportmenu             ok     158558
mrxguihudvehicledisguise         ok      20346
mrxguiinterface                  ok     101447
mrxguiloadlayout                 ok       2880
mrxguiloadscreen                 ok      11798
mrxguimanager                    ok      21225
mrxguinumericbox                 ok      37147
mrxguipauselayout                ok       1984
mrxguipausescreen                ok      30421
mrxguipda                        ok     112163
mrxguisatellite                  ok      61759
mrxguishell                      ok      38848
mrxguishellbootstrap             ok       5106
mrxguishelllayout                ok       3532
mrxguisniperscope                ok      17961
mrxguisupportshop                ok      26515
mrxguitextbuffer                 ok      50533
mrxguitutorial                   ok      33811
mrxgunship                       ok       8047
mrxharmstrike                    ok       5910
mrxhq                            ok      42028
mrxhqmanager                     ok       8973
mrxlaserguidedbomb               ok       6564
mrxlayermanager                  ok      18025
mrxmissionboundary               ok      14816
mrxmissionflow                   ok      52315
mrxmoab                          ok       1288
mrxmultipagemenu                 ok       5578
mrxmunitionspickup               ok      13509
mrxmusic                         ok      33545
mrxoilcon002delivery             ok       7679
mrxoutpostmanager                ok       1696
mrxparkinglotmanager             ok      10645
mrxplayer                        ok      47783
mrxplaystate                     ok       4706
mrxpmc                           ok      23072
mrxrewarddata                    ok      73164
mrxrocketartillery               ok       5649
mrxsatclusterbomb                ok       5979
mrxsatelliteguidedbomb           ok       5202
mrxshootinggallery               ok      13569
mrxshop                          ok      17313
mrxsmartbomb                     ok       4467
mrxsoldierdelivery               ok       9801
mrxsound                         ok       9720
mrxsoundbanks                    ok       8383
mrxsoundbootstrap                ok      37335
mrxsoundcategories               ok       3720
mrxstarter                       ok      25631
mrxstartermanager                ok       6392
mrxstate                         ok      17313
mrxstatsmanager                  ok      39515
mrxstrategicmissile              ok       6186
mrxsubtitle                      ok       1756
mrxsupport                       ok      38642
mrxsupportcopterdelivery         ok       8543
mrxsupportdata                   ok     126281
mrxsupportdelivery               ok      11148
mrxsupportdesignator             ok      13205
mrxsupportdesignatorbeacon       ok        873
mrxsupportdesignatorflare        ok       2058
mrxsupportdesignatorlaser        ok       3596
mrxsupportdesignatorsatellite    ok       8614
mrxsupportdesignatorsmoke        ok       6865
mrxsupportmanager                ok      21103
mrxsupportpickup                 ok      15611
mrxsupporttransit                ok      30537
mrxsurgicalstrike                ok       5294
mrxtankbuster                    ok       5869
mrxtask                          ok      18857
mrxtaskcontract                  ok      25193
mrxtaskcontractoutpost           ok      13483
mrxtaskcontractplaceholder       ok        545
mrxtaskjob                       ok      21185
mrxtaskjobcollecttype            ok       4326
mrxtaskjobdestroyset             ok       5638
mrxtaskjobdestroytype            ok       2225
mrxtaskjobverifyset              ok       9266
mrxtaskmission                   ok       5392
mrxtaskobjective                 ok      38647
mrxtaskobjectiveaccept           ok       1701
mrxtaskobjectiveaction           ok       4203
mrxtaskobjectivecaptureoutpost   ok       2507
mrxtaskobjectivedeliver          ok      40550
mrxtaskobjectivedestroy          ok       3907
mrxtaskobjectiveentervehicle     ok       7105
mrxtaskobjectiveextract          ok      12185
mrxtaskobjectiveprotect          ok       3144
mrxtaskobjectiverelease          ok       5949
mrxtaskobjectiveverify           ok      39021
mrxtaskrace                      ok      19393
mrxtaskstate                     ok        730
mrxtimer                         ok       8017
mrxtransit                       ok      21443
mrxtutorial                      ok       3195
mrxtutorialmanager               ok       9180
mrxunlockfanfare                 ok       8363
mrxutil                          ok      53762
mrxutil_shell                    ok       1432
mrxverifymanager                 ok      17383
mrxvosequence                    ok      12010
munitions                        ok      40997
oilrig                           ok      22423
opentankhatch                    ok        410
orientedblippable                ok       1425
outhouse                         ok         66
outpost                          ok      33502
paradrop                         ok       4363
paradroplocation                 ok       1386
paratrooper                      ok       1856
pmcgate                          ok        719
proximitymine                    ok       2327
pursuitcopter                    ok       5725
randomlyteleportplayer           ok       2258
repairpad                        ok       1969
shootinggallerytarget            ok        478
soldier                          ok       3622
spyhunter                        ok      16142
supportairplane                  ok       4251
tank                             ok       1142
telephone                        ok         66
treetrunk                        ok        890
treetrunkpalm                    ok        887
vehicleblippable                 ok       5651
verify_flash                     ok       3946

### shell (26 files)
mrxgui                           ok      23112
mrxgui_shellonly                 ok      15998
mrxguiattractlayout              ok       2162
mrxguiattractmode                ok       4616
mrxguibase                       ok     123799
mrxguibootstrap_shellonly        ok       1341
mrxguicinematic                  ok      29171
mrxguicinematiclayout            ok       5359
mrxguidialogbox                  ok      62457
mrxguiloadlayout                 ok       2880
mrxguiloadscreen                 ok      11798
mrxguimanager                    ok      21225
mrxguinumericbox                 ok      37147
mrxguishell                      ok      38848
mrxguishellbootstrap             ok       5106
mrxguishelllayout                ok       3532
mrxmultipagemenu                 ok       5578
mrxmusic                         ok      33545
mrxshellbootstrap                ok       1157
mrxsound                         ok       9720
mrxsoundbanks                    ok       8383
mrxsoundcategories               ok       3720
mrxsoundshellbootstrap           ok      14139
mrxutil_shell                    ok       1432
shell                            ok        331
shellbootstrap                   ok       5438
```
