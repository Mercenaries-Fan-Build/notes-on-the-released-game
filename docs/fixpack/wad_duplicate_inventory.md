---
status: current
evidence: proven
verified_on: 2026-07-22
witness: >
  Part A — `mercs2_probe --bin wad_dupes` over the four retail WADs of the target install
  (`C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames\data`): every ASET row re-parsed from
  the file, every duplicate's payload decompressed and compared byte-for-byte. Part B — the
  Ghidra decompilation of `mercs2_unpacked.exe` (mount state machine `FUN_004BFAF0`, archive-slot
  allocator `FUN_00874910`, per-archive ASET table build `FUN_008751D0`, per-archive lookup
  `FUN_00874E20`, reverse archive walk at `0x00875F7E` / `0x0087622D`), cross-checked against the
  shipped data (English.wad's six localized textures are registered under the BASE asset's hash,
  which only works under last-mounted-wins).
supersedes: []
---

# WAD duplicate inventory + registration order — Mercenaries 2 PC retail

**Target install:** `C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames` (read-only throughout).
**Tool:** `tools/wad_simulator/crates/mercs2_probe/src/bin/wad_dupes.rs` (new).

```
cargo build --release -p mercs2_probe --bin wad_dupes
./target/release/wad_dupes --validate \
  --wad "<install>/data/Loading.wad" --wad "<install>/data/shell.wad" \
  --wad "<install>/data/vz.wad"      --wad "<install>/data/English.wad" \
  --out wad_dupes.tsv
```

---

## 0. Headline answers

| Question | Answer | Evidence |
|---|---|---|
| Cross-WAD duplicate `(asset_hash, type_hash)` keys | **112** | `proven` |
| Intra-WAD duplicate keys | **0** — in all four WADs | `proven` |
| Duplicates that are byte-identical | **106** | `proven` |
| Duplicates that genuinely differ | **6** (all `texture`, all English.wad overrides) | `proven` |
| Mount order | Loading → loading-patch → *level* → *level*-patch → [extra] → English → English-patch | `proven` |
| Collision rule *across* WADs | **LAST-MOUNTED WINS** (reverse walk of the archive array) | `proven` |
| Collision rule *inside* the runtime chunk registry | **FIRST-WINS** (get-or-create) — a *different* layer | `proven` (prior work, re-confirmed) |
| Which `english` stringdb wins | **Neither — they are never mounted together.** `shell.wad`'s copy serves the front end, `vz.wad`'s copy serves gameplay. They are byte-identical today, so **a text fix must patch both**, or be delivered in `English-patch.wad`, which outranks both. | `proven` (identity, mount slots) / `inferred` (the shell↔vz slot share) |

---

# Part A — Duplicate inventory

## A.1 What counts as a duplicate

An asset's registry identity is **`(asset_hash, type_hash)`**, not `asset_hash` alone.

- `asset_hash` is `pandemic_hash_m2(<asset name>)` — a hash of the **name**, never of the content.
- `type_hash` comes from the WAD's own 36-entry **type table**, at **file offset `0x48`**, immediately
  after the 0x48-byte FFCS header. The entry count is the `DATA` chunk-row's `meta` word
  (header dword 8 = `0x24` = 36). The engine copies this table to `reader+0x458` in
  `FUN_00875140` and indexes it with the ASET row's `type_id` byte in `FUN_008751D0`.
- The engine's actual lookup key is **`type_hash ^ asset_hash`** (`FUN_008751D0`, with a
  `if key == 0 { key = asset_hash }` fallback).

So `ui_shell` appearing as `wavebank` *and* `soundbank` *and* `sounddb` in the same WAD is **not**
a collision — three distinct keys. That distinction removes ~570 false positives that a
hash-only grouping reports for `vz.wad`.

> **⚠ CORRECTION — `docs/type_hash_registry.md` / `mercs2_formats::aset_type_ids` are wrong for
> 12 of the 36 type ids.** The real table, read from the WAD and byte-identical in all four WADs,
> is below. Validated by sampling up to 3 ASET rows per `type_id` per WAD, decompressing the owning
> block and confirming it carries a UCFX entry `(asset_hash, types[type_id])`: **139 hit / 0 miss**
> (`wad_dupes --validate`). The old map guessed the ids the docs marked "singleton; id from ASET row",
> and got every one of them wrong.

```
 id  type_hash    name                     id  type_hash    name
 --  ----------   --------------------     --  ----------   --------------------
  0  0xFA46D8A8   fxdict            (!)    18  0xFA0B8DBC   chatter
  1  0x140E8728   guidmap           (!)    19  0x5B724250   model
  2  0x7131D39A   (unnamed)         (*)    20  0x34612F86   (unnamed)         (!)
  3  0x8F0A54E2   binary                   21  0x9F8BCA10   soundbank
  4  0x3B0AABF8   decaltable        (!)    22  0x1602815C   lowresterrain
  5  0x665EF13E   facefxanimationset       23  0xFE0E8320   scaleformgfx
  6  0xF753F6D0   wavebank                 24  0xACCE47F2   sequencetable     (!)
  7  0x39E5E978   stringdb                 25  0x4D7D30C4   (unnamed)         (!)
  8  0xC122545A   musicstatemap     (!)    26  0xEA4829D5   level             (!)
  9  0xE6B81A54   layer                    27  0xF011157A   texture
 10  0xE8DF4D87   musiccue          (!)    28  0xBCFE6314   path
 11  0x207359C7   animationtable           29  0x5608BD5A   effect
 12  0x600B904E   scrub                    30  0x6310807F   lineregion
 13  0xE5273C14   sounddb                  31  0x59B9DF6A   materialtable     (!)
 14  0xDE982D61   materialparam            32  0x7C569307   terrainmesh
 15  0x99E77ACE   font                     33  0xECE70371   animstatemachine  (!)
 16  0x18166555   animation                34  0x1CF649BB   facefxactor
 17  0x5647C35D   worldentity       (!)    35  0x42498680   script
```

`(!)` = the current in-repo map assigns this hash a **different** id.
`(*)` = absent from the in-repo map entirely.

## A.2 Corpus

| WAD | size | blocks | ASET rows | XOR-key clashes |
|---|---:|---:|---:|---:|
| `Loading.wad` | 2,490,368 | 8 | 10 | 0 |
| `shell.wad` | 29,622,272 | 36 | 575 | 0 |
| `vz.wad` | 2,565,537,792 | 11,370 | 30,645 | 0 |
| `English.wad` | 483,426,304 | 47 | 202 | 0 |

**Nothing was sampled for Part A.** All 31,432 ASET rows were enumerated, and all 224 rows belonging
to the 112 duplicate keys had their payload decompressed and compared in full (0 unresolved).
Only the *type-table validation* in A.1 is a sample (139 rows).

The "XOR-key clashes" column measures a failure mode the engine cannot detect: `FUN_008751D0`
stores only `type_hash ^ asset_hash`, so two *different* assets whose XOR agrees would be
indistinguishable to `FUN_00874E20`. Measured: **zero** in every WAD. `proven`.

## A.3 Intra-WAD duplicates

**None.** No WAD contains two ASET rows with the same `(asset_hash, type_hash)`. `proven`.

(The retail *patch* WAD format does permit this — `mercs2_formats::patch_wad::validate_blocks`
tolerates it deliberately — but none of the four base WADs uses it.)

## A.4 Cross-WAD duplicates — 112 keys

| WAD pair | keys | identical | divergent |
|---|---:|---:|---:|
| `shell.wad` + `vz.wad` | 106 | 106 | 0 |
| `shell.wad` + `English.wad` | 4 | 0 | 4 |
| `vz.wad` + `English.wad` | 2 | 0 | 2 |
| any pair involving `Loading.wad` | **0** | — | — |

`Loading.wad` (8 blocks, 10 rows — the boot loading screen and its font) shares **nothing** with the
other three. It is the only WAD in the set that cannot participate in a collision.

### By type

| type | keys | redundant payload (one copy each) | verdict |
|---|---:|---:|---|
| texture | 45 | 5,692,321 B | 39 identical, **6 divergent** |
| script | 22 | 336,705 B | all identical |
| scaleformgfx | 13 | 433,638 B | all identical |
| binary | 13 | 702 B | all identical |
| sounddb | 4 | 3,704 B | all identical |
| wavebank | 3 | **11,365,740 B** | all identical |
| soundbank | 3 | 49,008 B | all identical |
| font | 3 | 13,244 B | all identical |
| animationtable | 3 | 53,195 B | all identical |
| stringdb | 1 | **1,375,560 B** | identical |
| musicstatemap | 1 | 48,732 B | identical |
| musiccue | 1 | 23,452 B | identical |
| **total** | **112** | **19,396,001 B** | 106 / 6 |

### The big ones

| asset | type | bytes | where |
|---|---|---:|---|
| `ui_shell` | wavebank | 7,952,144 | `shell.wad#35` + `vz.wad#3525` |
| `ui_hud` | wavebank | 3,408,288 | `shell.wad#33` + `vz.wad#3505` |
| `English` | **stringdb** | 1,375,560 | `shell.wad#29` + `vz.wad#3419` |
| `cloud_noise` | texture | 1,048,710 | `shell.wad#32` + `vz.wad#2137` |
| `shell_mainmenu_dollarbill_elements` | texture | 524,445 | `shell.wad#18` + `English.wad#17` **(divergent)** |
| `global_seafoam01` | texture | 349,659 | `shell.wad#17` + `vz.wad#3185` |
| `global_rain` | texture | 349,654 | `shell.wad#17` + `vz.wad#3185` |
| `MrxGuiBase` | script | 88,174 | `shell.wad#17` + `vz.wad#3185` |

**Shape of the 106 shell↔vz duplicates:** they are exactly the front-end's shared kit — the four
Scaleform font families and their glyph atlases, the 22 `MrxGui*` / `MrxSound*` / `MRXMUSIC` Lua
scripts, the `common_*` / `font_16_*` UI atlases, `MUSIC` / `ui_hud` / `ui_shell` audio, the
`Sounds` / `VehicleEngines` animation tables, the `MusicMarkers` / `MusicTransitions` music data,
the `english` fonts and the `English` stringdb. This is *the same content baked twice*, once for
`shell.wad` and once for `vz.wad`. See §B.4 for why that is necessary.

### The 6 divergent keys — English.wad's localization override

All six sit in `English.wad` and all six are the same trick: **the English-specific artwork is
registered under the hash of the BASE asset's name, not its own.**

| key | base name (shell/vz side) | English.wad container `NAME` | payload |
|---|---|---|---|
| `0x169561D0` | `shell_mainmenu_dollarbill_elements` | `mainmenu_dollarbill_elements_english` | BODY differs |
| `0x78747B48` | `shell_mainmenu_text` | `mainmenu_text_english` | BODY differs |
| `0x69D3C746` | `shell_accept_back` | `accept_back_english` | BODY differs |
| `0x30A64191` | `shell_mainmenu_exit` | `mainmenu_exit_english` | BODY differs |
| `0x343B8D58` | `pause_graphic` | `pause_graphic_english` | **BODY identical**; only the embedded `NAME` chunk differs |
| `0xB04241E4` | `pda_titles` | `pda_titles_en` | INFO *and* BODY differ |

Verified with `wad_dupes --hash`:

```
0x343B8D58  pause_graphic            0xEFCB4275  pause_graphic_english
0xB04241E4  pda_titles               0x487C0542  pda_titles_en
0x69D3C746  shell_accept_back        0xBBD26100  accept_back_english
0x30A64191  shell_mainmenu_exit      0xB246259B  mainmenu_exit_english
0x78747B48  shell_mainmenu_text      0x42B84996  mainmenu_text_english
0x169561D0  shell_mainmenu_dollarbill_elements   0xB22939A8  mainmenu_dollarbill_elements_english
```

The English container's own name hashes to something else entirely; the ASET row and the block
entry both carry the **base** hash. **This is the shipped, retail proof that the WAD stack is
last-mounted-wins** — if the base copy won, none of the localized main-menu art would ever be seen.
`proven`.

*(Corollary for the fix pack: this is the sanctioned mechanism for replacing a base asset without
touching the base WAD — mint the override under the base asset's hash in a higher-ranked WAD.
It does not violate the "no destructive replacements" mandate at the file level, but it **does**
shadow the base asset at runtime, so treat it as a replacement.)*

The full 112-row table with per-side block indices, payload sizes and FNV-1a-64 payload hashes is
in the tool's TSV output; the summary table is reproduced in §Appendix A.

---

# Part B — How the engine registers, orders and resolves

Everything in Part B is read out of the Ghidra decompilation of the unpacked retail exe
(`output/_ghidra/mercs2_unpacked.exe_decomp.txt`; function addresses are true VAs). Nothing here
is inferred from filenames.

## B.1 There are exactly seven WAD slots, constructed once

`FUN_004BE0A0` (`0x004BE0A0`) constructs the WAD manager at `0x0149FDA0` with **seven** identical
reader objects (vtable `0x00BEA8F8`), stride `0x5B4`:

| manager offset | reader object | role |
|---|---|---|
| `+0x10` | `0x0149FDB0` | primary WAD |
| `+0x5C4` | `0x014A0364` | primary patch |
| `+0xB78` | `0x014A0918` | optional extra WAD (full path, config-gated) |
| `+0x112C` | `0x014A0ECC` | language WAD |
| `+0x16E0` | `0x014A1480` | language patch |
| `+0x1C94` | `0x014A1A34` | Loading WAD |
| `+0x2248` | `0x014A1FE8` | Loading patch |

Two string fields drive it:

- `+0x27FC` = `0x014A259C` — the **primary WAD basename** (`char[64]`)
- `+0x283C` = `0x014A25DC` — the optional extra WAD's **full path** (`char[256]`)

Both are written by one setter, `0x004BF820` (`SetWadNames(basename, extraPath)` — decoded from
the raw bytes; Ghidra's function export misses it, it is reached through a SecuROM splice thunk
at `0x02477DF0`). `FUN_004C1280` (`0x004C1280`, the return-to-front-end path) writes `"shell"`
into it directly and clears the extra path.

## B.2 Mount order — proven

`FUN_004BFAF0` (`0x004BFAF0`) is the mount state machine. With `this+8 == 1` it dispatches on
`this+0xC`:

| state | call site | function | file it opens |
|---:|---|---|---|
| 0–1 | `0x004BFC0B` | `FUN_004BFF80` | `%s\loading.wad` (`0x007AFF6C`) |
| 2–3 | `0x004BFC19` | `FUN_004C0040` | `%s\loading-patch.wad` (`0x007AFF7C`) |
| 4–5 | `0x004BFC27` | `FUN_004BFCE0` | `%s\%s.wad` (`0x007AFED0`) — name from `+0x27FC` |
| 6–7 | `0x004BFC35` | `FUN_004BFDA0` | `%s\%s-patch.wad` (`0x007AFF5C`) — same name |
| 8–9 | `0x004BFC43` | `FUN_004BFC70` | the optional extra WAD (skipped unless `DAT_01175BFC` or `+0x283C` is set) |
| 10–11 | `0x004BFC51` | `FUN_004BFE20` | `%s\%s.wad` — name from `(&PTR_s_english_00CF281C)[*DAT_01176018]` = the **language** |
| 12–13 | `0x004BFC5A` | `FUN_004BFEF0` | `%s\%s-patch.wad` — language patch; then `this+8 = 2` (done) |

The teardown branch (`this+8 == 3`, top of `FUN_004BFAF0`) closes them in the exact reverse order:
language-patch, language, extra, primary-patch, primary, loading-patch, loading.

So the **canonical mount order** is:

```
0  Loading.wad
1  loading-patch.wad        (if present)
2  <level>.wad              ← shell.wad  OR  vz.wad
3  <level>-patch.wad        (if present)   ← vz-patch.wad lands here
4  <extra>.wad              (config-gated; absent in retail)
5  English.wad              (language slot; "english" from PTR_s_english)
6  English-patch.wad        (if present)
```

Note `English.wad` is opened as `%s\%s.wad` with the lowercase name `english`. On Windows that
resolves to the shipped `English.wad` by case-insensitive matching; on a case-sensitive filesystem
(Proton/Wine with a case-sensitive prefix) it would not. Same for `english-patch.wad`.

## B.3 Slot assignment and the resolution walk — proven, and it is LAST-WINS

**Registration.** When a reader finishes parsing its header (`FUN_00874FB0`, `0x00874FB0`) it calls
`FUN_00874910` (`0x00874910`) to claim a slot in the global archive array:

```c
if (*(int *)(array + 0x100) < 0x40) {              // count < 64  (MAX_NUM_ASSET_FILES)
  for (i = 0; i < 0x40; i++)
    if (array[i] == 0) { array[i] = this; array[0x100]++; return i; }
}
return -1;
```

The array base is `PTR_PTR_01175014`, set in the streaming-manager constructor to
`streaming_mgr + 0x4C3E4`; the live count lives at `+0x100`, capacity **64**. Closing
(`FUN_00874F00`, `0x00874F00`) nulls the slot and decrements the count. Because the seven readers
open in the order of §B.2 and always close as a group, **slot index == mount order**.

**Resolution.** The archive array is walked **backwards**, from the highest index down:

```c
// FUN_00875E80 @0x00875E80  (call site 0x00875F7E)   and
// FUN_00876150 @0x00876150  (call site 0x0087622D)
puVar2 = PTR_PTR_01175014;
iVar4 = *(int *)(PTR_PTR_01175014 + 0x100);      // = number of mounted archives
do {
  iVar4--;
  if (iVar4 < 0) goto not_found;
  iVar6 = (**(code **)(**(int **)(puVar2 + iVar4 * 4) + 4))(&key);   // vtable+4 = FUN_00874E20
} while (iVar6 != 1);
(**(code **)(**(int **)(puVar2 + iVar4 * 4) + 0x1c))(&key, want);    // first hit wins
```

⇒ **the highest-index (last-mounted) archive that owns the key wins.** This is the same
`RedVirtualDisk` reverse-search the Mercs 1 source uses, and it is now confirmed *in the Mercs 2
PC binary* rather than assumed from filenames. `proven`.

Search order in practice, best to worst:

```
English-patch.wad  >  English.wad  >  [extra]  >  <level>-patch.wad  >  <level>.wad
                                                >  loading-patch.wad  >  Loading.wad
```

Two consequences worth knowing:

- `X-patch.wad` sits immediately above `X.wad`, so a patch always beats its own base. **But
  `loading-patch.wad` sits at index 1** — below `shell.wad`/`vz.wad`/`English.wad`. It can be
  overridden by them, which is the opposite of what its name suggests.
- `English.wad` outranks the level WAD. That is exactly why the six localized textures in §A.4
  work.

**The per-archive lookup itself** (`FUN_00874E20`, `0x00874E20`) returns three values, and the walk
only stops on one of them:

| stored value | returned | meaning |
|---|---|---|
| `>= 0` (an ASET row index) | `1` | this archive owns the asset **and names a block for it** → walk stops here |
| `-1` (miss sentinel) | `0` | not in this archive → keep walking down |
| `-2` | `-2` | the archive has a row but its `block_index` is `0xFFFF` (a body-less stub) → **the walk keeps going down** |

That `-2` path is the "resolve by hash from a lower archive" fallback the DLC-port work relies on.

**Per-archive table build** (`FUN_008751D0`, `0x008751D0`), for completeness — this is where an
*intra*-WAD duplicate would be decided:

```c
key   = types[row.type_id] ^ row.asset_hash;  if (key == 0) key = row.asset_hash;
value = (row.block_index != 0xFFFF) ? row_ordinal : -2;
slot  = key % table_size;
while (table_keys[slot] != 0) slot = (slot + 1) % table_size;   // probe for an EMPTY slot
table_keys[slot] = key;  table_values[slot] = value;  count++;
```

The insert **never compares keys** — it just finds a free slot. A second row with the same key
would land further from its home slot, and the linear-probe lookup would find the first one. So
**inside a single WAD the earliest ASET row wins**. Moot in practice: measured 0 intra-WAD
duplicates and 0 XOR-key clashes (§A.3).

## B.4 The two layers — and what "FIRST-wins" actually refers to

The project memory rule *"Registry insert is FIRST-wins, so a collision silently drops YOUR asset"*
is **confirmed, but it is a different layer** from the WAD stack, and the two rules run in opposite
directions. Getting them the wrong way round is the classic error here.

| layer | question it answers | rule | code |
|---|---|---|---|
| **1. WAD stack** | which *archive/block* supplies `(asset_hash, type_hash)` | **LAST mounted wins** (reverse walk of the 64-slot array) | `FUN_00875E80` @ `0x00875F7E`, `FUN_00876150` @ `0x0087622D`, slots by `FUN_00874910` |
| **2. Runtime chunk/component registries** | which *cell* holds a chunk once a block is resident | **FIRST writer wins** — get-or-create; an occupied slot returns the existing cell and creates nothing | `FUN_004CC130` (probe `FUN_008242B0`, `slot = key % size`) |

They compose exactly as retail intends: layer 1 picks the overriding block *first*, so its chunks
reach layer 2 *first* and win there too. A mod that adds a colliding hash to a **lower**-ranked WAD
is dropped at layer 1; one that adds it to a **higher**-ranked WAD shadows the base at both layers.

## B.5 `shell.wad` and `vz.wad` share one slot — they are never mounted together

This is the load-bearing conclusion for the fix pack, so here is the evidence split by strength.

**Proven:**
- There is exactly **one** `%s\%s.wad` reader and **one** basename buffer (`0x014A259C`) — §B.1.
- The basename is a runtime parameter with a setter (`0x004BF820`), not a constant.
- `FUN_004C1280` (`0x004C1280`) writes `"shell"` into it on the front-end path.
- `FUN_004BF8C0` (`0x004BF8C0`) drives a full **close-all → reopen-all** cycle
  (`DAT_0149FDA8 = 3; wait for 4; DAT_0149FDA8 = 1; wait for 2`) and then branches on
  `_stricmp(basename, "shell")` — so the code explicitly expects the basename to be something
  other than `"shell"` at other times.

**Inferred (strong):**
- The other value is the level name, i.e. `"vz"` (the level-name global `0x01175AB8` is what
  `FUN_004BCC90` uses to build the `<level>_preload` / `<level>_base` asset names). I could **not**
  statically locate the call site that writes `"vz"`: the setter's only reference is the SecuROM
  splice thunk at `0x02477DF0`, which itself has no static callers.
- Corroborated by the data: 106 of the 112 cross-WAD duplicates are `shell.wad`↔`vz.wad`, and they
  are precisely the front-end kit (fonts, Scaleform, `MrxGui*` scripts, `ui_shell`/`ui_hud`/`MUSIC`
  audio, the `English` stringdb). Baking 19 MB of content twice is only rational if the two archives
  are **not** co-resident. `docs/ui_blocks_inventory.md` reached the same conclusion from the
  extraction side ("font atlases duplicated for the world pack").

## B.6 Where the `-patch.wad` overlays sit

Directly above their own base, one slot up (§B.2, states 6–7 / 12–13 / 2–3). Concretely, for the
current install:

```
index 5   English.wad              ← beats everything below, in BOTH sessions
index 3   vz-patch.wad             ← present in this install: 20 blocks, 7,146 ASET rows,
                                      7,128 of which shadow vz.wad rows
index 2   vz.wad   (or shell.wad)
index 1   loading-patch.wad        (absent)
index 0   Loading.wad
```

> **⚠ The target install already carries a live `vz-patch.wad`** (17,039,360 B, 20 blocks,
> 7,146 ASET rows) from the character-import work. It outranks `vz.wad`, and 7,128 of its rows
> already shadow base rows. Fix-pack blocks must be **merged** into it
> (`mercs2_formats::patch_wad::merge_patch_wads`), never written over it — consistent with
> `docs/fixpack/bug_register.md`.

---

## C. Which `english` stringdb wins — and what to do about it

**Facts** (`proven`):

- Key `(0xB6A13123, 0x39E5E978)` = `pandemic_hash_m2("english")` × `stringdb`.
  (`pandemic_hash_m2("English") == pandemic_hash_m2("english")` — the hash lowercases via `| 0x20`.)
- It exists in **two** places: `shell.wad` block 29 and `vz.wad` block 3419, both
  `…\english_P000_Q3.block`. Payloads are **byte-identical** (1,375,560 B container;
  18,299 keys / 1,229,064 B heap per the earlier independent stringdb comparison).
- **`English.wad` contains no `stringdb` at all** — its 202 rows are VO wavebanks/soundbanks plus
  the six localized UI textures and the shell/guilayouts blocks.
- The engine asks for it by hashing the language name at runtime and requesting type
  `0x39E5E978` — see `FUN_004B87A0` (`0x004B87A0`), which inlines the FNV-1a/`|0x20`/`^0x2A`
  hash over `(&PTR_s_english_00CF281C)[*DAT_01176018]` and pairs it with `0x39E5E978`. It is
  *released* (`param_1 == 0`) and *re-requested* (`param_1 == 1`) across every shell↔gameplay
  transition (`FUN_004BC6D0` cases 2 and 7, `FUN_004C1280`), so the copy in use is re-resolved
  against whatever is mounted at that moment.

**Answer:** there is **no winner**, because there is no collision — `shell.wad` and `vz.wad` occupy
the same slot (§B.5). The front end is served by `shell.wad`'s copy; gameplay is served by
`vz.wad`'s copy. Both are live, at different times.

**Consequences for a text fix:**

1. **Patching only one is a half-fix.** A string edited in `vz-patch.wad` will not appear in the
   main menu / pause menu / options; a string edited in a `shell-patch.wad` will not appear in
   gameplay. Any shared UI string (button prompts, options text, PDA chrome) lives in both.
   `proven`.
2. **The clean single-file route is `English-patch.wad`.** It mounts at index 6 — above the level
   slot in *every* session — so one stringdb container registered under `(0xB6A13123, 0x39E5E978)`
   there outranks both base copies at once. `inferred`, but on strong footing: the language slot is
   mounted unconditionally (§B.2, proven), and `English.wad` already uses exactly this
   register-under-the-base-hash trick for six textures (§A.4, proven).
   **Verify before committing to it**: build a minimal `english-patch.wad` with one altered string
   and confirm the change shows up in *both* the front end and gameplay. If it does not, fall back
   to (3).
3. **Otherwise ship two overlays**: `shell-patch.wad` (front end) and merge into the existing
   `vz-patch.wad` (gameplay). Note the filename the engine builds is `%s\%s-patch.wad` with the
   basename it currently holds — `shell-patch.wad` and `vz-patch.wad` respectively.

---

## Appendix A — reproduction

```
# rebuild
cargo build --release -p mercs2_probe --bin wad_dupes

# full inventory + payload comparison + type-table validation
./target/release/wad_dupes --validate \
  --wad "…/data/Loading.wad" --wad "…/data/shell.wad" \
  --wad "…/data/vz.wad" --wad "…/data/English.wad" --out wad_dupes.tsv

# what does a name hash to?
./target/release/wad_dupes --hash pause_graphic --hash pause_graphic_english
```

The generated file is checked in at **`docs/data/wad_duplicates.tsv`** (224 rows).

`wad_dupes.tsv` columns: `asset_hash, type_hash, type_name, scope, wad, row_index, block_index,
block_path, lod_rungs, payload_bytes, payload_fnv1a64, verdict`. One row per side of every
duplicate key; `verdict` is `IDENTICAL` / `DIVERGENT` / `UNRESOLVED` for the whole key.

Pass `--wad` in **mount order** — the tool does not infer it.

## Appendix B — the 112 duplicate keys

Format: `asset_hash | name | type | payload bytes (one side) | locations (wad#block) | verdict`.
`(unresolved)` = the name is not in `docs/data/aset_names.csv`; for the six divergent textures the
real names are recovered from the containers' `NAME` chunks and listed in §A.4.

```
0x9CD06F1D  Sounds                      animationtable     43,241  shell#17 + vz#3185     IDENTICAL
0x11BBEE64  VehicleEngines              animationtable      8,521  shell#17 + vz#3185     IDENTICAL
0x5EA3291E  SoundsAppendix              animationtable      1,433  shell#17 + vz#3185     IDENTICAL
0x74D310BA  (unresolved)                binary                 54  shell#17 + vz#3185     IDENTICAL
0xA9A09EA1  (unresolved)                binary                 54  shell#23 + vz#3243     IDENTICAL
0x31A0438B  (unresolved)                binary                 54  shell#23 + vz#3243     IDENTICAL
0x3054834C  (unresolved)                binary                 54  shell#17 + vz#3185     IDENTICAL
0x8936ED45  (unresolved)                binary                 54  shell#23 + vz#3243     IDENTICAL
0x90BDCB0C  (unresolved)                binary                 54  shell#5  + vz#3007     IDENTICAL
0x7B51C28A  (unresolved)                binary                 54  shell#5  + vz#3007     IDENTICAL
0x642B6D94  (unresolved)                binary                 54  shell#4  + vz#2995     IDENTICAL
0x632D431C  (unresolved)                binary                 54  shell#5  + vz#3007     IDENTICAL
0xF0752EA2  (unresolved)                binary                 54  shell#4  + vz#2995     IDENTICAL
0xECFE0AE2  (unresolved)                binary                 54  shell#17 + vz#3185     IDENTICAL
0x5132AE24  (unresolved)                binary                 54  shell#17 + vz#3185     IDENTICAL
0x3A015234  (unresolved)                binary                 54  shell#4  + vz#2995     IDENTICAL
0x093F42E5  english_18                  font                4,738  shell#29 + vz#3419     IDENTICAL
0x13C26ABC  english_20                  font                4,738  shell#29 + vz#3419     IDENTICAL
0x339761F4  font_16                     font                3,768  shell#17 + vz#3185     IDENTICAL
0xE8DF4D87  MusicMarkers                musiccue           23,452  shell#12 + vz#3091     IDENTICAL
0xC122545A  MusicTransitions            musicstatemap      48,732  shell#12 + vz#3091     IDENTICAL
0x7269553D  (unresolved)                scaleformgfx      266,200  shell#9  + vz#3076     IDENTICAL
0x1AE56060  (unresolved)                scaleformgfx       65,367  shell#17 + vz#3185     IDENTICAL
0xAB0DAA23  loadingscreen               scaleformgfx       27,406  shell#17 + vz#3185     IDENTICAL
0x9C242D58  _shell_font_glyphs          scaleformgfx       14,088  shell#28 + vz#1966     IDENTICAL
0x3CC34BA0  (unresolved)                scaleformgfx        9,024  shell#17 + vz#3185     IDENTICAL
0x241661ED  _shell_bold_italic_font     scaleformgfx        7,383  shell#7  + vz#1965     IDENTICAL
0x8C0F2FC4  _shell_normal_font          scaleformgfx        7,249  shell#27 + vz#1967     IDENTICAL
0x18891AF0  _shell_bold_font            scaleformgfx        7,239  shell#6  + vz#1964     IDENTICAL
0x08DF88E2  GFxFontLib                  scaleformgfx        6,320  shell#17 + vz#3185     IDENTICAL
0xC1720898  _bold_italic_font           scaleformgfx        5,947  shell#17 + vz#3185     IDENTICAL
0x3BBEA46C  _italic_font                scaleformgfx        5,875  shell#17 + vz#3185     IDENTICAL
0x07216AAB  _bold_font                  scaleformgfx        5,771  shell#17 + vz#3185     IDENTICAL
0xBF840377  _normal_font                scaleformgfx        5,769  shell#17 + vz#3185     IDENTICAL
0xC9706D16  MrxGuiBase                  script             88,174  shell#17 + vz#3185     IDENTICAL
0xF148D251  MrxGuiShell                 script             40,650  shell#17 + vz#3185     IDENTICAL
0x9BA55054  MrxGuiDialogBox             script             38,967  shell#17 + vz#3185     IDENTICAL
0xD4D60271  MrxGuiNumericBox            script             28,786  shell#17 + vz#3185     IDENTICAL
0xF75D6CF1  MRXMUSIC                    script             23,989  shell#17 + vz#3185     IDENTICAL
0x9B50D72C  MrxGuiCinematic             script             20,440  shell#17 + vz#3185     IDENTICAL
0x0D87C65D  MrxGui                      script             16,882  shell#17 + vz#3185     IDENTICAL
0x73962EB2  MrxGuiManager               script             15,171  shell#17 + vz#3185     IDENTICAL
0xBFCA9DC9  MrxSound                    script              8,904  shell#17 + vz#3185     IDENTICAL
0x9CAA13BE  MrxSoundBanks               script              7,982  shell#17 + vz#3185     IDENTICAL
0xD00FDF05  MrxGuiLoadScreen            script              7,637  shell#17 + vz#3185     IDENTICAL
0xE07BEEAD  MrxGuiLTIPrecache           script              7,239  shell#17 + vz#3185     IDENTICAL
0x7457D375  MrxGuiShellBootstrap        script              6,839  shell#17 + vz#3185     IDENTICAL
0x460651BF  MrxMultiPageMenu            script              4,868  shell#17 + vz#3185     IDENTICAL
0x41E50B9D  MrxGuiAttractMode           script              3,945  shell#17 + vz#3185     IDENTICAL
0x5464E339  MrxSoundCategories          script              3,463  shell#17 + vz#3185     IDENTICAL
0x7749C276  MrxGuiCinematicLayout       script              3,428  shell#17 + vz#3185     IDENTICAL
0xFF512B83  MrxGuiShellLayout           script              2,708  shell#17 + vz#3185     IDENTICAL
0xF1DF7A3B  MrxGuiLoadLayout            script              2,361  shell#17 + vz#3185     IDENTICAL
0xA0C0C986  MrxGuiAttractLayout         script              1,931  shell#17 + vz#3185     IDENTICAL
0x2F66EAAF  MrxUtil_Shell               script              1,335  shell#17 + vz#3185     IDENTICAL
0x66046C1F  MrxGuiLTIPrecacheLayout     script              1,006  shell#17 + vz#3185     IDENTICAL
0x4111ECDA  MUSIC                       soundbank          24,204  shell#14 + vz#3129     IDENTICAL
0xDD4573C5  ui_hud                      soundbank          18,736  shell#33 + vz#3505     IDENTICAL
0xE7A89B5C  ui_shell                    soundbank           6,068  shell#35 + vz#3525     IDENTICAL
0x4111ECDA  MUSIC                       sounddb             1,972  shell#14 + vz#3129     IDENTICAL
0xDD4573C5  ui_hud                      sounddb             1,132  shell#33 + vz#3505     IDENTICAL
0xE7A89B5C  ui_shell                    sounddb               364  shell#35 + vz#3525     IDENTICAL
0x37750257  Mercs2Globals               sounddb               236  shell#13 + vz#3111     IDENTICAL
0xB6A13123  English                     stringdb        1,375,560  shell#29 + vz#3419     IDENTICAL
0xCC3D675F  cloud_noise                 texture         1,048,710  shell#32 + vz#2137     IDENTICAL
0x169561D0  shell_mainmenu_dollarbill…  texture           524,445  shell#18 + English#17  DIVERGENT
0x2873D252  global_seafoam01            texture           349,659  shell#17 + vz#3185     IDENTICAL
0x27AE0359  global_rain                 texture           349,654  shell#17 + vz#3185     IDENTICAL
0x7D853E09  _shell_font_glyphs_f0       texture           262,288  shell#17 + vz#3185     IDENTICAL
0x78747B48  shell_mainmenu_text         texture           262,286  shell#18 + English#17  DIVERGENT
0x60CD8D84  global_gui_hud02            texture           262,283  shell#1  + vz#2237     IDENTICAL
0x4F569BB1  font_glyphs_f0              texture           262,281  shell#17 + vz#3185     IDENTICAL
0x45D10A6F  global_noise                texture           174,895  shell#17 + vz#3185     IDENTICAL
0x40BA4038  english_20_main             texture           131,285  shell#29 + vz#3419     IDENTICAL
0x6C3B162F  english_18_main             texture           131,285  shell#29 + vz#3419     IDENTICAL
0xD2380186  _shell_bold_italic_font_f0  texture           131,221  shell#17 + vz#3185     IDENTICAL
0x976263CD  _shell_normal_font_f0       texture           131,216  shell#17 + vz#3185     IDENTICAL
0xF9E81CC9  _bold_italic_font_f0        texture           131,215  shell#17 + vz#3185     IDENTICAL
0x97F4EBA1  _shell_bold_font_f0         texture           131,214  shell#17 + vz#3185     IDENTICAL
0x69D3C746  shell_accept_back           texture           131,212  shell#18 + English#17  DIVERGENT
0x4AD459F5  _italic_font_f0             texture           131,210  shell#17 + vz#3185     IDENTICAL
0x5BBD3A0C  _normal_font_f0             texture           131,210  shell#17 + vz#3185     IDENTICAL
0x1D3F5708  _bold_font_f0               texture           131,208  shell#17 + vz#3185     IDENTICAL
0x343B8D58  pause_graphic               texture           131,208  vz#3185  + English#41  DIVERGENT
0x3B9C7A57  gfxfontlib_f0               texture           131,208  shell#17 + vz#3185     IDENTICAL
0x7CD08DD1  radial_flare                texture            87,511  shell#17 + vz#3185     IDENTICAL
0x8CF694E1  common_20_buttons           texture            65,754  shell#8  + vz#3058     IDENTICAL
0x3601AA34  common_18_buttons           texture            65,754  shell#8  + vz#3058     IDENTICAL
0x2C7C1360  font_16_main                texture            65,746  shell#10 + vz#3079     IDENTICAL
0x30A64191  shell_mainmenu_exit         texture            65,678  shell#18 + English#17  DIVERGENT
0x5E84EA6D  global_defaultcubemap       texture            65,664  shell#17 + vz#3185     IDENTICAL
0xCDC5E1DA  common_20_objectives        texture            32,986  shell#8  + vz#3058     IDENTICAL
0xB04241E4  pda_titles                  texture            32,901  vz#3185  + English#41  DIVERGENT
0xDF6921B1  common_18_objectives        texture            16,602  shell#8  + vz#3058     IDENTICAL
0x2ABE822D  common_20_factions          texture            16,600  shell#8  + vz#3058     IDENTICAL
0x0F323243  common_18_rewards           texture            16,599  shell#8  + vz#3058     IDENTICAL
0xEBB855A6  common_20_rewards           texture            16,599  shell#8  + vz#3058     IDENTICAL
0xF64BAABA  loadingscreen_overlay       texture            16,528  shell#17 + vz#3185     IDENTICAL
0xD54EA3DE  loadingscreen38             texture            16,522  shell#17 + vz#3185     IDENTICAL
0x6F604C49  loadingscreen8              texture            16,521  shell#17 + vz#3185     IDENTICAL
0x1D7DD146  common_18_factions          texture             8,408  shell#8  + vz#3058     IDENTICAL
0x702F011E  font_16_buttons             texture             8,405  shell#19 + vz#3228     IDENTICAL
0x0F67AD36  sundisk                     texture             2,858  shell#3  + vz#2696     IDENTICAL
0x471E8BF0  common_18_tm                texture               722  shell#8  + vz#3058     IDENTICAL
0xB20C8CBF  common_20_tm                texture               722  shell#8  + vz#3058     IDENTICAL
0x313554DE  font_16_tm                  texture               720  shell#11 + vz#3089     IDENTICAL
0x8C2F2876  common_20_quote             texture               469  shell#8  + vz#3058     IDENTICAL
0xC6DF0AF7  common_18_quote             texture               469  shell#8  + vz#3058     IDENTICAL
0x663FC7BA  ui_gradient                 texture               390  shell#17 + vz#3185     IDENTICAL
0xE7A89B5C  ui_shell                    wavebank        7,952,144  shell#35 + vz#3525     IDENTICAL
0xDD4573C5  ui_hud                      wavebank        3,408,288  shell#33 + vz#3505     IDENTICAL
0x4111ECDA  MUSIC                       wavebank            5,308  shell#14 + vz#3129     IDENTICAL
```

## Appendix C — corrections this work produced

1. **`docs/type_hash_registry.md` / `mercs2_formats::aset_type_ids::type_id_for_type_hash` are
   wrong for 12 of 36 type ids.** ★ **The CODE half is fixed as of 2026-08-01** — `types.rs`,
   `type_name` and `aset_type_ids` are regenerated from the in-WAD table and pinned by
   `mercs2_formats/tests/type_ids_match_the_wad.rs`, which reads offset `0x48` at test time rather
   than encoding a fourth copy. `docs/type_hash_registry.md` itself is still uncorrected. The authoritative table is in the WAD at file offset `0x48`
   (count = header dword 8). Correct table in §A.1; validated 139 hit / 0 miss. Most visibly:
   `0xC122545A` is id **8** (not 26), `0x5647C35D` is id **17** (not 8), `0xEA4829D5` is id **26**
   (not 20), `0xE8DF4D87` is id **10** (not 4). `docs/data/aset_export.csv`'s `type_name` /
   `type_hash` columns inherit those errors — its `type_id` and `asset_hash` columns are correct.
2. **"Asset lookups search patch WAD first (reverse-order)"** in `docs/patch_wad_format.md` and
   `docs/dlc_loader_cross_reference.md` was marked *inferred from the Mercs 1 source*. It is now
   **proven in the Mercs 2 PC binary** (§B.3) — and additionally proven from shipped data (§A.4).
3. **`loading-patch.wad` does not sit at the top of the stack.** `docs/patch_wad_format.md` §5
   speculates it has "special handling" and is "likely loaded first, before the main game WADs" —
   it *is* loaded first, which means it is ranked **lowest**, so `shell.wad` / `vz.wad` /
   `English.wad` override it, not the other way around.
4. **`aset_export.csv` is complete and current** for this install: re-deriving from the four WAD
   files reproduces its per-WAD row counts (10 / 575 / 30,645 / 202) and the identical set of
   112 cross-WAD duplicate keys.
