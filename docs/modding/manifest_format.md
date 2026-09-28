# Shipment manifest format

The reference for `manifest.yaml` — the file that describes a Mercenaries 2 mod.

A **Shipment** is a mod package. The **Quartermaster** (`qm`) reads one, checks it, and builds it
into an overlay WAD. This document is the contract between the two; `qm rules` lists every check and
links back here.

Start from the [template repo][template] rather than from a blank file.

Format version: **2**, the only format. A manifest declaring any other `format` — older or newer,
including `1` — is rejected loudly (M0100) rather than parsed optimistically: a field this build does
not understand is a field it would silently drop.

## The file

`manifest.yaml` at the Shipment root. `.yml`, `.json` and `.toml` are also accepted and parse
through the same model, so nothing is expressible in one and not the others. **Exactly one** — two
manifests is an error rather than a precedence puzzle.

YAML is preferred, and it is what `qm` writes, because this file is mostly prose-adjacent metadata
that people read and review.

```yaml
format: 2

shipment:
  name: my-shipment          # lowercase, dashes; becomes _build/<name>.wad
  version: 1.0.0             # semver, MAJOR.MINOR.PATCH
  target: retail             # retail | reimpl
  authors: [your-name]
  description: One line about what this does.

load:
  requires:
    - { shipment: lua-bridge, version: "^1.0.0" }

contributions:
  - kind: replace_texture
    target: pmc_hum_mattias_v3_ub
    image: src/skin.png
```

`target` picks the engine: `retail` is the shipped game, `reimpl` the fan-build engine. There is no
value meaning "both" — a Shipment that claims to target both has almost certainly been tested
against neither, and the layers available differ (ASI plugins exist only on retail).

`shipment.name` is a slug and must not be a **reserved name** (M0211): the stem of a DLL no
Shipment may ship — `pmc_bb`, `cruise`, `dxwrapper`, `binkw32` — compared case-insensitively.
`shipment.version` must be semver (M0100).

### `supersedes`

A top-level list of legacy files this Shipment replaces — typically a mod's old loose-file install:

```yaml
supersedes:
  - { dest: on_load, file: 1_Ess.lua }
```

`dest` is one of the `place_file` destination names and `file` a single filename. While any of them
is still in the game folder (matched case-insensitively), `qm build` refuses and `qm preflight` /
`qm link` report **M0208**. qm never deletes the file; remove it (Modkit offers to, with undo) and
build again.

## Names and hashes

Anywhere an existing asset is referenced you may write **either** a name or a bare `0xHHHHHHHH`
hash. A `0x…` reference *is* that hash; anything else is treated as a name and hashed for you.

```yaml
target: pmc_hum_mattias_v3_ub    # preferred
target: "0x6F84F6A3"             # equally valid
```

**A name is preferred, not required.** The engine's hash is one-way, so a hash cannot be turned back
into a name, which makes a manifest full of them hard to read, review or diff. `qm` warns (M0130) and
offers the name when it can reverse one — but the hash works, and the warning never blocks a build.

Requiring names would be a rule the game itself does not follow: the base data ships hashes, and our
name table does not cover every asset. If you are modding something unnamed, the hash is the only
thing you *can* write.

What the linter is actually guarding against is a **wrong** pairing. An earlier draft of this
document paired `ch_veh_boat_destroyer` with `0xE54047D5` — a hash that belongs to
`al_veh_boat_destroyer`. Nothing about it looked wrong. Writing the name, where you have one, is what
makes that class of drift impossible.

## Folder layout

```
my-shipment/
  manifest.yaml     this file
  src/              your .glb / .png / .lua / raw payloads
  _build/           qm output: <name>.wad + .sha256 + build.log + placement.json   (gitignore this)
  README.md         your own description
```

Every path in the manifest is relative to the Shipment root and must resolve **under `src/`**. A path
that escapes the root — through `..` or a symlink — is refused (M0111), because a Shipment has to
mean the same thing on someone else's machine as on yours.

### `placement.json`

Every `qm build` and `qm link` output directory holds one `placement.json`: what each output is,
its size and sha256, and where a deploy step puts it. An output that produced nothing writes
`"placements": []`.

```json
{
  "format": 2,
  "placements": [
    { "name": "my-shipment.wad", "bytes": 81920, "sha256": "…", "destination": { "kind": "overlay" } }
  ]
}
```

`format` is 2. `destination.kind` is one of:

| kind | fields | what the deploy step does |
|---|---|---|
| `overlay` | — | mounts the WAD as a patch overlay on `vz.wad` |
| `game_folder` | `relative` | copies the file to that path under the game folder (the Code layer) |
| `data_wad` | `relative`, `display` | places a new base WAD at `relative` (`data/<name>.wad`, [`add_language`](#add_language)); `display` is the label a language selector shows |
| `language_patch` | `language`, `relative` | merges the WAD's blocks, with every installed Shipment's for that language, into `data/<language>-patch.wad`, which the engine mounts directly above `data/<language>.wad` (`FUN_004BFEF0`, `"%s\%s-patch.wad"` with the language table's entry) |
| `shell_patch` | — | merges the WAD's blocks, with every installed Shipment's, into `data/shell-patch.wad`, which the engine mounts above `shell.wad` in the front end (`FUN_004BFDA0` with the name `shell`, which `FUN_004C1280` writes at `0x004C12DD`) |
| `stream_copy` | `from`, `to` | copies the game file `from` to `to`, both relative to the game folder; `bytes` and `sha256` describe `from` as the build read it, and no bytes are in the output directory |

A link output's patch WAD merges last. The kinds are `Destination` in `mercs2_quartermaster`'s
`build.rs`.

## Contribution kinds

| kind | layer | required fields |
|---|---|---|
| `replace_texture` | Data | `target`, `image` |
| `add_texture` | Data | `name`, `image` (`normal_map:` optional) |
| `add_model` | Data | `name`, `model` (`donor`, `group`, `textures`, `retarget` optional) |
| `add_outfit` | Data + Script | `name`, `slug`, `display`, `wearer`, `model` (`donor`, `textures`, `retarget`, `single_group` optional) |
| `add_sound` | Data + Script | `bank`, `category`, `load_in`, `cues` ([sound cue fields](#sound-cue-fields)) |
| `replace_sound_bank` | Data + Script | `bank`, `category`, `cues` (`language` on a `vo_*` bank) |
| `replace_sound_cue` | Data + Script | `bank`, `category`, `cue` (`language` on a `vo_*` bank) |
| `add_animation` | Data | `name`, `clip`, `trnm` (`events` optional) |
| `replace_animation` | Data | `target`, `clip`, `trnm` (`events` optional) |
| `add_movie` | Data | `name`, `movie` |
| `add_ui` | Data + Script | `name`, `movie` |
| `patch_lua` | Script | `target`, `append` |
| `edit_stringdb` | Data | `target`, `strings` |
| `add_language` | Data (new base WAD `data/<name>.wad`) | `name`, `display`, `strings` (`base` optional) |
| `edit_state_machine` | Data | `target`, `states` |
| `edit_world` | Data | `layer`, `edits` |
| `activate_layer` | Script | `layer` (`replaces:` optional) |
| `native_hook` | Code | `target`, plus a `plugin` or a symbol/detour descriptor, plus `touches` |
| `place_file` | Code | `file`, `dest` |
| `add_runtime_dll` | Code | `dll` |
| `raw` | any | `payload`, `target_layer`, `touches` |

This table covers the kinds documented on this page. **`qm kinds` is the authoritative list** of every
kind the installed `qm` reads (`qm kinds --json` prints `{"format":2,"kinds":[...]}`); a client that
offers kinds should read it rather than keep a copy.

**Removed kinds.** `add_ai_squad_template` and `add_schema` were removed in qm 3.1.0. A manifest that
still uses one fails to parse, with a message naming the kind as removed. `add_ai_squad_template`
shipped bytes under an author-supplied type id and type hash for an asset nobody has
reverse-engineered, so nothing about it could be checked — ship such bytes with `raw` and a declared
`touches`. `add_schema` had nothing to load it: a schema is the column layout of a component table
inside a placement layer, not a standalone asset.

`donor` is **optional on `add_outfit`**: omit it and the build hosts the outfit on the wearer's own
hero model (`pmc_hum_mattias` / `pmc_hum_chris` / `pmc_hum_jen`), validated against the game stack
(Plan 04, resolved Q2). Set `donor:` only for a variant host such as `pmc_hum_mattias_v3`.

On `add_model` `donor:` is still **required** — a prop has no wearer to name its host, and its rig
must match the geometry class, which is not safe to guess (the weight-transfer history shows a wrong
host produces a model rigged to nothing). Supply it explicitly.

**Write a bare hash QUOTED in YAML.** A name is preferred and a bare `0xHHHHHHHH` is legal
anywhere an asset is referenced — but unquoted, YAML reads `0xEB6F1B2D` as the integer
`3949927213` and the manifest fails to load with *"invalid type: integer, expected a string"*.
So `target: "0x6F84F6A3"`, `touches: ["0xE54047D5"]`.

### `edit_state_machine`

Rewrites a destructible's destruction **state machine** — the `SWIT`/`NODE`/`STAT`/`CHDR`/`CEXE`
family that decides which body shows in which damage state, and the Enter/Exit command scripts
(`SHOW`/`HIDE`/`SetState`) each state runs. `target` is the model; `states` is a YAML file.

**Extract, then edit.** Authoring the machine by hand is punishing, so pull the baseline the model
already carries and change that:

```sh
qm extract-states al_veh_boat_destroyer --game <dir> > src/states.yaml
```

The dump reads in names where a hash reverses (states, HIER nodes, commands) and keeps the script
opcodes as plain integers; edit it and point `states:` at it. The whole family is **regenerated** from
your file every build, so you can **add or remove** nodes and states, not only rewrite them — the
writer rebuilds the descriptor table, re-bases the container, and recomputes the CSUM. A no-op (edit
nothing) still ships the container byte-for-byte, proven across all 1,311 retail destructibles.

⚠ **State names are the engine's global vocabulary, not labels you own.** `SetState` /
`SetStateOnMsg` key on a shared set of hashes — `PristineState`, `DamagedState`, `DestroyedState`,
`GoneState`, `InitState`, … — so a state you rename to a novel name (or add with one) is **never
reached by the damage system**: it ships but is dead. **M0193** warns when an edited state is outside
that vocabulary and was not already in the model. The edits that matter are a state's **Enter/Exit
command scripts** (which HIER subtrees to `SHOW`/`HIDE`, which emitters to start) and its switch
slots — change what a state *does*, using state identities the model and the vocabulary already
carry.

The overlay carries **only** the edited model as a single-entry block — no block-mate is shadowed.
Its ASET row is copied from the base and the builder re-points `_P000` at the new block while
sentinelling the finer LOD rungs (which degrade to coarse tier at distance, they do not dangle), so
the LOD chain is recomputed rather than the whole base block re-emitted.

The **permanent, world-scale** counterpart — making a building ruined for the rest of a mission — is
the `vz_state` overlay, a separate mechanism scoped in
[`vz_state_world_overlay_scope.md`](vz_state_world_overlay_scope.md).

### `edit_world`

Moves, rotates or re-models the **placed entities** of a world layer — the permanent, world-scale
counterpart to `edit_state_machine`'s per-model destruction edits. Where `edit_state_machine` changes
what a destructible *becomes*, `edit_world` changes where a thing *is*: the `vz_state` /
`layers_static` placement layers are the `UCFX`→`CHDR`→`COMP` tree of 42-byte `Transform` + `Name` +
`ModelName` records that the world load reads to spawn the level.

`layer` is a **needle** matched against the layer blocks in the game stack (`vz_state_pmccon004`,
`vz_state_pmc`, or just `vz_state` for the first match). `edits` is a `src/`-relative YAML file.

**Extract, then edit.** Author against the baseline the layer already carries:

```sh
qm extract-world vz_state_pmccon004 --game <dir> --names production_names.json > src/world.yaml
```

Each edit names one entity by its **key** (the placement hash, quoted `"0xHHHHHHHH"`) or by its
`Name` where one reverses, and supplies any of `pos: [x,y,z]`, `quat: [x,y,z,w]`, `model: <name>`:

```yaml
edits:
  - entity: "0x8B7DE1F5"   # my_custom_helipad
    pos: [1240.5, 12.0, -880.25]
    quat: [0, 0, 0, 1]
  - entity: crate_stack_03
    model: al_prop_barrel_red
```

The overlay is an **in-place patch**, not a regeneration: the layer block is shadowed with the base
bytes and only the named records' transform/model words are overwritten, because the `Placement`
parse drops the record's `+16` pad and `+36` tail and cannot round-trip a full rebuild. An edit that
resolves to no change is a hard error — a no-op overlay would ship an identical block for nothing.
Two Shipments editing one layer conflict (M0207): each overlay shadows the whole layer, so one
Shipment's edits would be silently absent. An `add_placement` on the same layer conflicts with it
too.

Scope and the step-0/1/2 proof are in
[`vz_state_world_overlay_scope.md`](vz_state_world_overlay_scope.md).

### `activate_layer`

Turns a normally-hidden world-state layer **on** — the permanent, whole-mission counterpart to
`edit_world`. Where `edit_world` moves things inside a layer, `activate_layer` decides which layers
the world streams in at all.

A `vz_state` overlay is switched at runtime by the game's own layer manager:

```lua
MrxLayerManager.MarkForAddition("vz_state_pmccon004_destroyed")
MrxLayerManager.MarkForRemoval("vz_state_pmccon004_pristine")
```

These are the exact calls a vanilla contract makes (`OilCon001.Activated` adds `_act1` and removes
`_pristine`; an outpost capture removes its defense layer and adds its captured one). `layer` is the
name to add; `replaces:` is an optional list to remove first (the pristine or prior overlay this one
supersedes).

```yaml
  - kind: activate_layer
    layer: vz_state_pmccon004_destroyed
    replaces:
      - vz_state_pmccon004_pristine
```

**No `src/` file and no Data half.** `layer` / `replaces` are layer **names**, not assets you ship —
the layer must already exist in the WAD (retail carries 900-odd of them, or a companion `edit_world` /
`raw` ships one). The whole contribution is a Lua registration, baked into the Quartermaster-owned
**`qm_modloader`** — the same expandable load space and one-line `wifpmcinterior` trampoline `add_ui`
uses (see [`add_ui`](#add_ui) for how that works). So N `activate_layer` and `add_ui` mods share one
loader and one trampoline, merge cleanly, and each mark runs under `pcall`. The resident script never
grows with mod count.

⚠ **Layer names are CASE-SENSITIVE**, and a wrong one is silent — `MarkForAddition` on a name no
layer carries reaches nothing at runtime. **M0194** (advisory, needs the game stack) warns when the
`layer` or any `replaces` name has no layer-typed ASET row, unless a companion contribution in the
same install ships it.

The trigger is the moment the mod loader runs — PMC-interior entry, every session — which is the one
resident hook the linker is proven to merge. For a mission-timed switch (a layer that should flip at a
specific objective) you still want a bespoke `patch_lua` in the contract; `activate_layer` is the
turnkey "turn this overlay on" face.

### `add_movie`

Adds a Scaleform GFx movie as a `cfx_pack` asset. The `.gfx`/`.cfx` bytes ship verbatim (retail
carries both, so neither is normalised to the other); `name` is the identity a Lua caller passes to
`SetSwfFile` / `GetShellGfxFilename`, so it is a bare name like `topbar` or `MINIMAP`, no extension.

The engine references movies by **fixed name**, so how a movie reaches the screen decides what
`add_movie` can do:

- **Replace** a shipped movie by using its exact name (`SHELL`, `pause_menu`, `MINIMAP`, a
  `*_briefing`, …). Same name → same hash → last-wins, and every UI site that already names it now
  serves yours. This is the proven UI-mod path.
- **Add a new** movie under a novel name and load it from Lua. The engine binds a movie to a
  `FlashWidget` by NAME — the shipped `loadingscreen_standalone` movie is loaded exactly this way
  (`mrxgui.lua`): `w = FlashWidget:new(); w:SetSwfFile("<name>"); w:Play(); w:SetVisible(true)`.
  A `patch_lua` carrying that boilerplate, plus the movie, is a complete working addition — this is
  a PROVEN capability, not a hypothesis. What stays author-specific is only *where* the widget
  attaches and *when* it shows (a boot overlay, a hotkey toggle, a HUD element parent). Use
  **`add_ui`** below to have the Quartermaster bake that boilerplate for you; reach for a bare
  `add_movie` + `patch_lua` only when you need full control of the trigger.

**M0192** (advisory, needs the game stack) fires when `name` matches no shipped movie, to catch the
novel-name case above before it ships something the game never shows. It does **not** fire on
`add_ui`, which references its own movie by construction.

### `add_ui`

The turnkey face over `add_movie` for a movie that should simply **appear on screen**. Same two
fields — `name`, `movie` — and the Data half is byte-for-byte an `add_movie` (the same `cfx_pack`,
the same primary ASET row). The difference is the Script half: `add_ui` also enrols a `FlashWidget`
that plays the movie, so it shows without any hand-written Lua.

How that Script half works is the part worth understanding, because it is how **every** future
composed addition reaches the game without mods fighting over one script:

- The Quartermaster mints a script it owns, **`qm_modloader`**, as a genuinely new `scripts_vz`
  asset (a new block entry *and* its primary type-35 ASET row — the two halves the DLC's own loader
  ships for a new importable module). Every UI mod's `FlashWidget` registration is baked into this
  one script. It is the *expandable load space*: it grows as mods are added.
- The game's resident script (`wifpmcinterior`) gets only a **one-line trampoline** — it `import`s
  `qm_modloader` when the PMC interior loads and runs it once. This line never changes no matter how
  many UI mods are installed, so the resident script is not edited and re-edited per mod.
- Installing several UI mods together merges cleanly: their registrations concatenate into one
  `qm_modloader`, in load order (the order `requires` and the installer's list give; see
  [Composition](#composition)), so the same set always produces the same bytes,
  and the single trampoline is shared. Each registration runs under `pcall`, so one bad movie cannot
  wedge the loader.

`add_ui` makes the movie *appear* (created, played, visible, and parked in `_QM.ui[name]` so you can
reach it from Lua). Its on-screen **rect and hide trigger** are still yours — add a `patch_lua` that
manipulates `_QM.ui["<name>"]` if you need to place or toggle it. For a movie that *replaces* a
shipped one, use `add_movie` with the exact shipped name instead; a replacement needs no widget of
its own.

### `edit_stringdb`

Corrects or localises UI text. The Shipment's own overlay carries one edited copy of the target
string table, with all of the Shipment's string contributions to that table applied in order;
installed beside other Shipments editing the same table, `qm link` merges all their edits into one
table, in load order (see [String tables are merged](#string-tables-are-merged)).
Arbitrary-length
edits are supported — the codec (`mercs2_formats::stringdb`, proven byte-identical against all six
retail language tables) rebuilds the heap and re-points the offsets.

`strings:` is a `src/`-relative text file, **one edit per line**:

```
[Menu.Play] = New text
0x0000B29D = an edit by hash, for a key whose bracket name you do not have
# a comment
```

Line-oriented rather than YAML on purpose: UI text carries `:`, `%s`, quotes and colons that a YAML
value would demand escaping. A key not present in the table is a hard error, named — a
silently-dropped correction is worse than a failed build.

⚠ **Shared tables are a half-fix (M0191).** The language tables (`english`, `french`, …) are served
from BOTH `shell.wad` (front end) and `vz.wad` (gameplay). One overlay reaches one mount point, so a
shared UI string edited in a single Shipment may show in only one. Deploy it to mount last in every
session, or ship a shell copy too (`docs/fixpack/wad_duplicate_inventory.md` §C).

### `add_language`

Adds a **new language** the game never shipped. It is the one kind that places a new **base WAD**,
`data/<name>.wad`, rather than an overlay: the engine builds both the mounted file name
(`.\Data\<name>.wad`) and the language's string-table key from the same name, and it exits if that
base WAD is missing.

```yaml
  - kind: add_language
    name: klingon          # the WAD file name and the string table's name
    display: Klingon       # the label a selector (Modkit) shows; not written into any WAD
    strings: src/klingon.txt
    base: english          # the shipped table to start from; omit for english
```

- `strings:` has the same format as [`edit_stringdb`](#edit_stringdb)'s. The build copies the `base`
  table, applies these edits (keys you leave out keep the base text; a key the base does not have is
  a hard error), and re-keys the copy under the new language's name. A file with no strings at all is
  refused.

`data/<name>.wad` is the whole of the language's data; the Shipment overlay carries nothing for it.
The build needs the game stack, and opens `English.wad` beside `vz.wad` as well as the stack. The
WAD holds:

| what | from | as |
|---|---|---|
| the string table | the `base` table, translated | `m2(name)`, type `0x39E5E978` |
| fonts `<name>_18`, `<name>_20` | `<base>_18`, `<base>_20` | the font's one `MTRL` reference to `<base>_18_main` / `<base>_20_main` repointed to `<name>_18_main` / `<name>_20_main`; every other byte as the base has it |
| atlases `<name>_18_main`, `<name>_20_main` | `<base>_18_main`, `<base>_20_main` | the base atlas under the new name hash; the texture's `NAME` chunk unchanged |
| voice-over tables | every soundbank, sounddb and wavebank of `English.wad`, streamed and embedded | re-keyed from `m2("<bank>.english")` to `m2("<bank>.<name>")`, computed from the bank hash each table carries; the table bytes unchanged |

A font reaches its atlas only through the name hash in its `MTRL` chunk, and the engine reads a
texture's `NAME` chunk into a buffer nothing uses, so a re-keyed atlas needs no other edit
([`eighth_language_wiring.md` §10](../reverse_engineer/eighth_language_wiring.md#10-fonts-atlases-and-the-engine-language-table)).
The fonts and atlases of `base` are read from `vz.wad`'s stack and from `shell.wad`; a copy in both
must match byte for byte (M0219 when `base` has none). In the retail install only `english` has
them (`shell.wad` block `blocks\Shell\english_P000_Q3.block`), so `base` is `english` in practice.

Retail Lua loads a `vo_*` bank as `<bank>.<language>` (`_GetLocalizedName`,
`mrxsoundbanks.lua:80-87`), so the re-keyed tables are the ones the new language's voice-over
loads. The streamed `vo_stream` wavebank's waves play from `Audios\vo_stream.<language>.pws`
(`_OpenFile`, `mrxsoundbanks.lua:96-107`), so the build records a `stream_copy` placement from
`data/Audios/vo_stream.english.pws` to `data/Audios/vo_stream.<name>.pws`, with the source's size
and sha256, and the deploy step copies the file. The build writes two placements for the language:

- `data_wad { relative: data/<name>.wad, display }`;
- `stream_copy { from: data/Audios/vo_stream.english.pws, to: data/Audios/vo_stream.<name>.pws }`.

`vo_stream` is the one streamed wavebank of `English.wad`. Its other 42 wavebanks are
**embedded**: each carries its waves' audio inside the table (1,498 waves in all), so the re-keyed
copy in `data/<name>.wad` carries that audio to the new language and the 1,492 English cues that
play those waves play them in the new language too. They are the 13 `vo_*Con*` banks
(`vo_allCon001`, `vo_oilCon021`, `vo_pmcCon003`, …), the 25 `vo_job_*` banks (`vo_job_all_Conrad`,
`vo_job_heros`, `vo_job_pmc`, …), `vo_helirec001`, `vo_jetRec001`, `vo_mechRec001`, and
`vo_solanoahj`, whose waves the `vo_Chris`, `vo_Jen`, `vo_mattias` and `vo_Misc` soundbanks play.
Retail's `vo_job_all_gonzalez` wavebank holds 26 waves of all-zero samples, and its copy is the
same. The census is the retail test `english_wad_embedded_voice_over_wavebank_census`
(`mercs2_quartermaster/tests/build_retail.rs`).

- **M0200** refuses a `name` that is not a lowercase `[a-z0-9_]` token (it becomes a file name) or
  that is a WAD the game already ships (`vz`, `shell`, `loading`, `english`, `french`, `german`,
  `italian`, `spanish`, `japanese`, `russian`). So `add_language` can only add a WAD, never shadow
  one.
- Switching the game into the new language is **not** this kind's job, and a Shipment does not
  carry anything for it. PC has no in-game language selector — the language is picked at boot from
  the OS locale — and selecting an installed language is handled by Modkit. The engine side is in
  [`language_asi_hook_contract.md`](../reverse_engineer/language_asi_hook_contract.md).
- Two Shipments adding the same language name conflict (M0207). The build needs the game stack, to
  read the `base` table.

### `add_model`

Adds a new model by injecting your geometry into a **donor** — a shipped model whose rig, materials
and state machine it borrows, read-only.

```yaml
  - kind: add_model
    name: my_crate               # the new asset's name
    model: src/crate.glb
    donor: oc_veh_helicopter_md500
    group: 3                     # optional: the donor draw group that hosts the geometry
    collision: follow_geometry   # optional, rigid only: donor (default) | follow_geometry
    textures:                    # optional: the model's own maps
      diffuse: src/crate_dm.png
```

Without `retarget:` the model is lowered **rigidly**: the geometry goes into one donor draw group
(`group:`, default 0) and the rest are neutralised. With `retarget:` it takes the skinned path
([below](#retarget--the-skinned-path-add_model-add_outfit)).

`collision:` picks the prop's static collision: `donor` keeps the donor's `PHY2` as is;
`follow_geometry` regenerates it from your own mesh. It is a rigid-path option — the skinned path's
collision is ragdoll/capsule and is never re-authored — so **M0202** refuses
`collision: follow_geometry` together with `retarget:` rather than ignore it.

`textures:` gives the model its own skin. Each map (`diffuse`, `specular`, `normal`) ships as its own
resident texture, `<name>_dm` / `_sm` / `_nm`, and the donor's MTRL is repointed onto it at that
slot:

- **rigid** — the hashes the **host group's** materials name at that slot. Each of those materials
  must carry the textured flag `0x0080`: a material with flags `0x0000` is flat-shaded and ignores
  whatever texture is bound
  ([`field_guide.md` Trap 2](field_guide.md#trap-2--the-model-loads-fine-then-the-game-crashes-when-you-look-at-it)).
  The build refuses a host group with such a material rather than ship a map nothing draws — pick a
  `group:` whose materials are textured.
- **skinned** (`retarget:`) — every donor material's hash at that slot.

Either way, a map with nothing to repoint onto, or a repoint that matches nothing, fails the build.
PNG only, 8-bit, dimensions a multiple of 4; normals are BC3/DXT5nm, diffuse and specular BC1 unless
the source carries real alpha.

### `retarget:` — the SKINNED path (`add_model`, `add_outfit`)

Without `retarget:` a model is lowered RIGIDLY: hosted on the donor with empty joints. Correct for
a prop, wrong for anything that animates. `retarget:` selects the skinned lowering, which re-poses
the source rig onto the donor's and writes palette-relative `BLENDINDICES` plus the matching
`INFO(56)` range table — the shipped skinning format.

```yaml
    retarget:
      from: valve          # cod | valve | mixamo | unreal | pandemic | generic
      bones:               # optional; the RESOLVED map
        ValveBiped.Bip01_Spine2: Bone_Chest
        ValveBiped.Bip01_L_Calf: Bone_LShin
        SomeHelperBone: ~   # `~` drops the bone
```

`from:` is documentation and a sanity check, not the instruction — detection runs from the bone
names in the file, and a mismatch is reported.

`bones:` is the reproducibility record. Omit it and the build derives the map itself from the
convention tables, which is the same map the Workshop previews; supply it and a rebuild by someone
else reproduces exactly what the author approved, including any hand adjustment. A stale entry is
an error, not something to skip.

**Do not hand-write it.** `mercs2_workshop --export-shipment <model.glb> --rebind-target <donor>`
writes the whole Shipment — manifest plus `src/` — with the map it actually used.

### `textures:` (`add_outfit`)

```yaml
    textures:
      diffuse: src/skin_dm.png
      specular: src/skin_sm.png
      normal: src/skin_nm.png
```

Each map becomes its own resident texture block, and every donor hash at that MTRL slot is
repointed onto it. **Needs `retarget:`** — `add_outfit`'s rigid path performs no repoint, so an
outfit without it wears the donor's skin whatever is listed here, and the build refuses rather than
substituting. (`add_model`'s rigid path does repoint; see [`add_model`](#add_model).)
PNG only, 8-bit, dimensions a multiple of 4.

Slot order is `0 = diffuse, 1 = SPECULAR, 2 = NORMAL` — not the intuitive d/n/s. Normals are
BC3/DXT5nm; diffuse and specular are BC1 unless the source carries real alpha. A repoint that
matches nothing fails the build: the texture would ship with nothing referencing it.

### `single_group:` (`add_outfit`)

```yaml
    single_group: true
```

Forces the whole mesh into ONE donor draw group, wearing the source's OWN retargeted weights.
Use it for a **dense foreign-rig** import — one whose weights reference more than ~48 distinct
bones (a `donor_transfer` resample of the retail rig easily does). Above that ceiling an outfit is
otherwise split across several host draw groups (the multi-group balanced split), where the injector
fills a few and neuters the donor's others — a donor-structure-dependent layout a foreign-rig
character has been observed to render unstably on (it culls / teleports as the camera rotates).
`single_group` takes the proven single-host path instead: it skips donor-weight resampling (the
thing that inflates the bone count), so the conform's own weights — limbs mapped 1:1 by the
convention table, fingers folded to the hand — fit one group.

What it does with textures (no manual `textures:` needed): the build reads the GLB's OWN embedded
per-material diffuse maps, bakes them into a single atlas, remaps each part's UVs into its atlas
cell, and repoints the donor's diffuse slot onto it — plus a flat matte specular and a flat normal
so the donor's maps don't mis-light the atlased UVs. One draw group carries one material, so this is
the price of `single_group`: no per-material maps and no donor-resampled limb polish. The trade buys
placement stability, which is what a foreign-rig outfit needs first. A manual `textures:` block, if
present, overrides the auto-atlas.

### `replace_texture`

Same hash, fully resident, so your image must match the target's dimensions — a mismatch is a hard
error rather than something the builder can quietly rescale.

Two warnings are worth understanding before you pick a target:

- **M0007** — the texture *streams*. Its row names finer LOD rungs held in other blocks, and a
  fully-resident replacement stops those from being named. Hero textures (`pmc_hum_*`) are already
  single-block and are unaffected; most world textures are not.
- **M0009** — the texture has no primary ASET row of its own; retail carries it as a shared
  sub-entry. Replacing it mints a primary row, which is what makes your change take effect — and
  also means every asset sharing that texture now gets your version.

Neither blocks a build. Both change what your mod affects.

### `add_animation`

Adds a new Havok animation clip, as an `animation` asset (ASET type 16) under `name`.
`replace_animation` takes the same sources and swaps a shipped clip in place, same hash (`target`
instead of `name`).

```yaml
  - kind: add_animation
    name: my_wave
    clip: src/anim/my_wave.hkx      # Havok 5.5 packfile, one hka*Animation
    trnm: src/anim/my_wave.trnm     # the track → bone binding
    events: src/anim/my_wave.evnt   # optional: timed events
```

The build assembles the container every retail clip uses — `info` (`01 00`), `data` (the `clip`
bytes), `trnm`, and `evnt` when `events` is given, packed with its CSUM — and ships each source
verbatim. The layout is in [`anim_clip_format.md`](../anim_clip_format.md), including the `evnt`
format:

```text
[u32 count]  then per event:  [f32 seconds] [name, NUL-terminated ASCII] [category, NUL-terminated ASCII]
```

Retail's events are sound cues, voice lines and gameplay markers (`opendoor`), with categories such
as `sound`, `sound_surface`, `vo` and `camera`, or none.

- `clip` is a Havok 5.5 packfile (magic `57 E0 E0 57 10 C0 C0 10`) as the Havok content tools write
  it.
- `trnm` is `[u16 count][u16 flags][u32 lead][count × u32 bone name-hash]`, the hashes being HIER
  bone name-hashes of the rig the clip drives.

**M0213** checks that the three belong together before anything is built, and the build checks it
again: the clip must be a packfile with a readable `hkaAnimation`; the `trnm` must be exactly
`8 + 4·count` bytes with `count` equal to the clip's `numTransformTracks`; the events must parse,
with finite, non-negative times in non-decreasing order. An event may fire after the clip's
duration — retail does.

`replace_animation` needs the game stack: its target must be a shipped **Havok clip**. 29 retail
`animation` assets are `MANM` keyframe animations instead, and a replace naming one is refused —
these sources cannot express one. Omitting `events` on a replace ships the clip with no `evnt`,
whatever the clip it replaces had.

### `add_sound`

Adds a new sound bank. `Sound.CueSound("<cue name>")` plays one of its cues once the bank is
loaded.

```yaml
  - kind: add_sound
    bank: mymod_sounds         # the bank name; every table of the bank carries m2(bank)
    category: ui               # the category of every cue's group (M0216)
    load_in: [gameplay, front_end]   # where the bank loads: one or both, each once (M0221)
    cues:
      - name: mymod_click      # Sound.CueSound("mymod_click")
        wave: src/click.wav
        group_gain_db: -4
        cue_gain_db: -6
        pitch_semitones: 0
        positional: false
        min_distance: 10
        max_distance: 1000
        distance_exponent: 1
        doppler_scale: 1
        start_limit: 0
        sound_id: 0x1C2B3A49
        priority: 0.95
        group_20: 1
        cue_16: 0
        clip_hash: 0x1C2B3A49
```

The build encodes the bank's three tables — soundbank (ASET type 21, type hash `0x9F8BCA10`),
sounddb (13, `0xE5273C14`) and wavebank (6, `0xF753F6D0`) — as three entries of one block under
`m2(bank)`, at `blocks\VZ\mod_<hash>.block`, each with one primary ASET row, the shape of every
retail bank ([`audio_code_map.md` §11.1](../reverse_engineer/audio_code_map.md#111-conventions-and-packaging)).
Each cue becomes one embedded wave, one single-wave group and one single-track cue at the cue's
index, and one sounddb entry routing `m2(name)` to it (§11.6).

The bank plays only once it is loaded, and retail Lua loads banks by name. `load_in` names the
sessions whose loader loads it, and the block ships to each one's WAD:

| `load_in` | the loader | the block ships in |
|---|---|---|
| `gameplay` | `qm_modloader`, run from `wifpmcinterior._OnEnter` (PMC-interior entry, every session) and unloaded after `MrxSoundBootstrap.ExitGame` | the Shipment overlay |
| `front_end` | `qm_shell_modloader`, run after `MrxSound.EnterShellState` (the main menu opening) and unloaded after `ExitShellState` ([The front-end loader](#the-front-end-loader)) | the shell patch |

`load_in` is required: it lists at least one session, each once (**M0221**). Each loader runs
`MrxSoundBanks.LoadWaveBank(bank)` then `MrxSoundBanks.LoadSoundBank(bank)`, the calls
`mrxsoundbootstrap.lua` makes for the game's own banks. Loading a soundbank also requests the
sounddb of the same name (`0x00602768`–`0x006027A1`), which is what makes FindCue see the cues. A
`qm build` of a Shipment with an `add_sound` links the loaders, so it needs the game stack and the
Lua corpus.

A cue named like a cue the game already has never plays: FindCue answers from the first loaded table
that has the guid, which is the game's (**M0220**). To change a game cue, use
[`replace_sound_cue`](#replace_sound_cue). A bank named `vo_*` is refused (**M0215**): retail Lua
appends the language to such a name before loading it.

### Sound cue fields

Every field is required; none has a default. A cue is one PCM16 wave played by one single-wave group
through one single-track cue — the shape of retail `ui_PDA_Open_01_st` (cue 57 → group 70 of
`ui_hud`). Offsets are into the group, the cue or the wave record of
[`audio_code_map.md` §11.4–§11.5](../reverse_engineer/audio_code_map.md#114-soundbank). In YAML a
`u32` field takes a decimal or an unquoted `0x` hex integer.

| field | type | written to | what the engine does with it | evidence |
|---|---|---|---|---|
| `name` | string | cue `+0x00` guid = `m2(name)`; the sounddb entry's guid | `Sound.CueSound(name)` looks up `m2(name)` | FindCue `FUN_00835a70` (PROVEN) |
| `wave` | `src/` path | wave record and its embedded PCM16 data | the samples the wave plays | the strict reader `mercs2_audio::wav::read_pcm16_wav`: RIFF/WAVE, format 1, 16 bits, 1 or 2 channels, rate above 0, whole frames (M0214) |
| `group_gain_db` | number, dB | group `+0x2C`, as the f32 `10^(dB/20)` | base volume of the sound instance | `FUN_0083d770` (PROVEN); −4 dB gives `0x3F21866C` and −6 dB `0x3F004DCE`, retail `ui_PDA_Open_01_st`'s bits |
| `cue_gain_db` | number, dB | cue `+0x08`, as the f32 `10^(dB/20)` | multiplies the cue's volume each frame | `FUN_00835060` (PROVEN) |
| `pitch_semitones` | f32 | group `+0x30` | base pitch of the sound instance, in semitones | `FUN_0083d700` (PROVEN) |
| `positional` | bool | group `+0x14` (1 / 0) | `true`: with an emitter, the instance plays from the emitter's own source, positioned; `false`: from the shared 2D source | `FUN_00837830`, `0x008378A9` (PROVEN) |
| `min_distance` | f32 | group `+0x18` | full volume up to this distance from the listener | `FUN_0083d3a0` (PROVEN) |
| `max_distance` | f32 | group `+0x1C` | silent from this distance | `FUN_0083d3a0` (PROVEN) |
| `distance_exponent` | f32 | group `+0x24` | exponent of the fall-off between the two distances | `FUN_0083d3a0` (PROVEN) |
| `doppler_scale` | f32 | group `+0x28` | how much of the Doppler shift applies | `FUN_0083b120` (PROVEN) |
| `start_limit` | u8 | cue `+0x06` | the cue starts only while fewer than this many instances of it are playing; 0 starts it every time | `FUN_00834ad0` (decomp 627053–627066) compares it with a counter in the cue's runtime record that `FUN_008354e0` raises when an instance plays and `FUN_00835850` lowers when one finishes (PROVEN) |
| `sound_id` | u32 | group `+0x00` | one reader: for the ids `0xEA1343AA`, `0xC05D8686` and `0xBB8AE67D` nothing plays unless the game runs in English; any other value has no known effect | `FUN_008369e0`, `0x00836A27`–`0x00836A45` (PROVEN); no other reader in the Pal code `0x0082A000`–`0x00842000` (INFERRED, bounded search) |
| `priority` | f32 | group `+0x10` | voice-stealing priority: with every voice busy, a new instance takes the voice of the lowest-priority wave only when its own priority (this value times its distance volume) is higher; otherwise no wave is created for it | `GetWavePriority` `FUN_00837e10` (`0x00837EDF`), `FUN_00837830` (`0x00837A0C`) (PROVEN) |
| `group_20` | f32 | group `+0x20` | no reader known; carried as written | copied into the wave at `+0x68` (`0x00838F70`); the only reader of wave `+0x68` is the getter `0x00838F30` at vtable `+0x44` of both wave vtables, and it has no call site in `0x00828000`–`0x00842000` (INFERRED) |
| `cue_16` | u16 | single-track cue `+0x16` | no reader known; carried as written | the cue's `{bank, group}` reference is read at `+0x10` and `+0x14` only (`FUN_0082e7d0`, `FUN_0083d410`); the instance field that holds the reference (`+0x28`, written at `0x00836A05`) is otherwise only cleared (`0x00836BEE`) (INFERRED) |
| `clip_hash` | u32 | wave record `+0x00` | no reader known; carried as written | `FUN_00837830` reads the record at `+0x05`, `+0x06`, `+0x08`, `+0x0C`, `+0x14`, `+0x18`, `+0x1C`, `+0x20` and not `+0x00` (`0x00837883`–`0x0083789F`, `0x00837AB7`–`0x00837AF4`); no wave method reads the record pointer it stores as data (INFERRED) |

The retail values of each raw field are counted by the census tests in `mercs2_audio`'s
`tests/retail_fields.rs` (`group_sound_id_against_the_playing_cue_guids`, `group_priority_values`,
`group_word_20_values`, `cue_start_limit_values`, `single_track_cue_word_16_values`,
`wave_clip_hash_against_sound_id_and_cue_guid`) and listed in
[`audio_code_map.md` §11.4](../reverse_engineer/audio_code_map.md#114-soundbank).

The build derives the rest of each table:

- group `+0x04` = `m2(category)`, `+0x08` = 0, form 0 (single-wave), and its wave
  `{wavebank hash, wave index, weight 1.0}` — the engine does not read a single-wave group's weight
  (`FUN_0083d410` returns the wave at `+0x34` directly, decomp 633049–633051, PROVEN), and it is 1.0
  in every retail single-wave group (`single_wave_group_weight_is_one`);
- cue form 0 (single-track), its `{bank hash, group index}`, and its length `+0x0C` by §11.4's rule;
- the wave record's channels, format, rate, size, frame count and data offset, from the WAV;
- the sounddb, sorted by guid.

### `replace_sound_bank`

Replaces a bank the game ships, by the name the game's Lua loads it under.

```yaml
  - kind: replace_sound_bank
    bank: vo_mattias
    language: german           # vo_* banks only (M0217)
    category: vo
    cues:
      - name: MATTIAS_LINE_001
        wave: src/mattias_001.wav
        # … every sound cue field
```

The build encodes the bank's soundbank and sounddb from `cues` and ships both under the bank's entry
name — `bank`, or `<bank>.<language>` for a `vo_*` bank — so the game's own load of the bank reads
them. A cue of the game's bank that `cues` does not declare is gone from the bank; nothing checks
for it.

The waves go in a wavebank of their own, `qm_<shipment>_<entry>` (for example
`qm_my-mod_vo_mattias.german`), which the loader of each session that loads the bank loads
(`LoadWaveBank` only; [below](#where-a-sound-override-ships)). A retail wavebank can be shared between banks
([`audio_code_map.md` §11.4](../reverse_engineer/audio_code_map.md#114-soundbank)), and the `vo_*`
banks have none of their own (their waves stream from `vo_stream`, `mrxsoundbootstrap.lua:218-245`),
so the replacement's waves are not written into a game wavebank. The override wavebank's name does
not start with `vo_`, so Lua loads it under exactly that name.

Where the tables ship is [below](#where-a-sound-override-ships). Two Shipments replacing one bank
conflict (M0207).

### `replace_sound_cue`

Replaces one cue of a bank the game ships, leaving every other cue of the bank as the game has it.

```yaml
  - kind: replace_sound_cue
    bank: ui_hud
    category: ui
    cue:
      name: ui_PDA_Open_01_st  # the cue it replaces
      wave: src/pda_open.wav
      # … every other sound cue field
```

The build forks the game's soundbank — or the replacement, when a `replace_sound_bank` of the same
entry is in the installed set — appends one single-wave group, and rewrites the cue as a
single-track cue playing it. The cue keeps its index, so the bank's own sounddb still routes to it
and is not shipped; every other cue and group is byte-identical. The wave goes in the override
wavebank `qm_<shipment>_<entry>`, as for `replace_sound_bank`. The cue must be in the bank
(**M0218**).

Two Shipments replacing different cues of one bank compose: `qm link` merges every
`replace_sound_cue` of the set into one soundbank per bank ([Sound banks are
merged](#sound-banks-are-merged)). One cue replaced by two Shipments conflicts (M0207).

### Where a sound override ships

An override's tables and its wavebank ship to every level that both carries the bank and loads it —
each level WAD runs its own Lua, and `shell.wad` and `vz.wad` are never mounted together — and that
level's loader loads the wavebank:

| bank | read from | loaded in | the tables and the wavebank ship to |
|---|---|---|---|
| `vo_*` | the declared `language`'s WAD (`English.wad`, …) | gameplay | the tables to that language's patch (`language_patch/<language>.wad`, merged into `data/<language>-patch.wad`); the wavebank to the Shipment overlay |
| `ui_hud`, `music` | `vz.wad` and `shell.wad` | gameplay and the front end | both to the Shipment overlay and to the shell patch (`<shipment>.shell-patch.wad`, merged into `data/shell-patch.wad`) |
| `ui_shell` | `shell.wad` | the front end | both to the shell patch |
| any other bank `vz.wad` carries | `vz.wad` | gameplay | both to the Shipment overlay |

Where retail loads each bank
([`audio_code_map.md` §11.10](../reverse_engineer/audio_code_map.md#1110-where-banks-are-loaded)):

- **The front end** loads `ui_shell`, `ui_hud` and `music` in `MrxSound.EnterShellState`
  (`shell/mrxsound.lua:9-14`, called from `mrxguishell.lua:505`) — the only bank-load call site among
  `shell.wad`'s 28 scripts — and `shell.wad` carries exactly those three soundbanks.
- **Gameplay** loads 11 banks by name in `MrxSoundBootstrap.LoadBanks`
  (`resident/mrxsoundbootstrap.lua:195-245`, `ui_hud` and `music` among them) and the `vo_*` banks
  per language. `vz.wad` carries 76 soundbanks: those 11, `ui_shell`, and 64 that no Lua in the
  corpus loads by a literal name; an override of one of the 64 loads in gameplay.
- `vz.wad` also carries the front end's scripts and `ui_shell`, but its copy of
  `EnterShellState` runs only from `GameBootstrap.Start`, which returns at once once the main menu
  has handed over to the game (`Sys.FinishedShell()`, `gamebootstrap.lua:43-46`). So `ui_shell`
  loads in the front end only, and a `ui_shell` override ships to the shell patch alone.

`ui_hud`, `ui_shell` and `music` are byte-identical in both archives (`cue_guids_across_sounddbs`).
A bank in no carrier, or one no carrier loads (a `vz.wad`-only `ui_shell`), is **M0218**.

A shell patch is stamped with `shell.wad`'s CSUM row, the WAD it mounts above.

### The front-end loader

The front end runs `shell.wad`'s own Lua VM, so the gameplay loader is not there. When any
registration loads a bank in the front end, the build links a second loader into `shell.wad`'s
scripts block (`blocks\Shell\resident_P000_Q3.block`, 28 scripts) and ships the block in the shell
patch, with every ASET row copied from `shell.wad`:

- **`qm_shell_modloader`** — a new script the Quartermaster mints into that block. It publishes
  `_G._QMS` with `load_sounds()` and `unload_sounds()`, generated by the same code as the gameplay
  loader's: each bank's `LoadWaveBank` (and, for an `add_sound` bank, `LoadSoundBank`), in load
  order and then by bank name, each bank loaded once until it is unloaded (`_QMS.loaded`). No
  callback is passed, so the batch callback retail's `EnterShellState` sets (`_StartShellMusic`)
  stands.
- **A trampoline appended to the front end's `mrxsound`** (its source from the corpus's `shell/`):
  `EnterShellState` and `ExitShellState` each call retail's first, then `import("qm_shell_modloader")`
  and `_QMS.load_sounds()` / `_QMS.unload_sounds()`. The front end calls them when the main menu
  opens and closes (`mrxguishell.lua:505`, `:589`) and when the shell exits
  (`mrxsoundshellbootstrap.lua:99`).

`import` finds a script by the hash of its name and the script type through the engine's typed
asset lookup, with no block or WAD in the key (`_SYS._IMPORT` = `0x005AE2D0`), so a script minted
into the shell patch's copy of the block is found like the shell's own.

The gameplay loader works the same way in `vz.wad`: `wifpmcinterior._OnEnter` calls retail's, then
`_QM.load_sounds()` (each bank once per session, `_QM.loaded`) and `_QM.run()`; a trampoline
appended to `mrxsoundbootstrap` makes `ExitGame` call retail's `UnloadBanks`, then
`_QM.unload_sounds()`. The sound calls run with no `pcall` and no existence check.

`MrxSoundBanks` reports no failure: its completion callback takes no argument
(`mrxsoundbanks.lua:141-152`) and the engine's carries no flag, and a `LoadWaveBank` of a name no
mounted WAD holds is released after a timeout with no error
([`audio_code_map.md` §11.2](../reverse_engineer/audio_code_map.md#112-resolving-a-cue)). So the build
checks it: every bank a loader loads must have its wavebank among the blocks shipped to that
loader's level, in `qm build` and in `qm link` (for the link, the blocks each Shipment's own build
ships); a bank without one is a build error naming the bank and the level.

### The `language` field

`language` names which language's copy of a `vo_*` bank a sound override replaces. Its values are
the engine's language table (`0x00CF281C`) without `english_uk` and `allcaps`, which the game selects
only from the command line and whose Lua `GetLanguage` reports English:

`english` · `spanish` · `italian` · `french` · `german` · `japanese` · `russian`

The table entry is the base name of the language's WAD (`.\Data\<entry>.wad`) and the suffix retail
Lua appends to a `vo_*` bank's name ([`eighth_language_wiring.md`
§10](../reverse_engineer/eighth_language_wiring.md#10-fonts-atlases-and-the-engine-language-table)).
A bank that is not `vo_*` has one copy for every language and takes no `language` (**M0217**).

When a contribution declares a language, `qm` and the Workshop open `vz.wad` and then that
language's WAD from the same folder (every declared language, in table order); `add_language` adds
`English.wad`. A declared language whose WAD is not there is an error — the retail install ships no
`japanese.wad`.

## Composition

Two Shipments that touch the same thing must not silently produce one winner and one no-op. This is
the part of the format that exists for that.

### The engine gives no single answer

Four subsystems, four different rules, running at once:

| subsystem | resolution |
|---|---|
| WAD stack | last mounted wins |
| runtime chunk registry | **first** writer wins |
| string databases | last registered wins, capped at 8 |
| ASI plugins | no arbitration at all |

So "load order" is not a universal answer, and for ASI plugins there is no order that resolves a
collision at all.

### Merge classes

Every claim a Shipment makes carries a class:

- **`Exclusive`** — one claimant; a second is a hard error. Raw blocks, function redefinitions, HQ
  starters, anything opaque.
- **`KeyedSet { key }`** — union by key; a duplicate key is an error. Outfits key on
  **`(wearer, slug)`**, not `slug` alone: retail reuses `Original` and `ChickenSuit` across all three
  heroes.
- **`OrderedList`** — append-only, with companion values the Quartermaster derives rather than
  trusting.
- **`LastWins`** — later wins and load order is genuinely the answer. Texture replacement.

**Unrecognized targets are `Exclusive`.** The Quartermaster knows the wardrobe list is append-only
because somebody reversed it and wrote it down; it cannot infer that for something nobody has
studied. Failing closed keeps an unknown edit *expressible* — it just cannot silently co-install.

### Conflict classes by kind

Two Shipments in one installed set conflict (**M0207**, a hard error before anything is built) when
they claim one target in a class that cannot be shared:

| kind(s) | what two Shipments on one target do |
|---|---|
| `replace_texture` | `LastWins` — load order picks; never a conflict |
| `replace_shader`, `replace_fx`, `replace_animation`, `replace_phy2`, `replace_terrain_cell`, `edit_state_machine`, `edit_world` | `Exclusive` — conflict. An `edit_world` and an `add_placement` on one layer conflict too |
| `patch_lua` (and the rows `add_outfit`, `add_ui`, `activate_layer`, `add_shop_item` append) | compose, on **any** script — see below |
| `replace_lua` | `Exclusive` — conflicts with another `replace_lua` **and** with a `patch_lua` of the same script |
| `edit_stringdb`, `add_stringdb_keys`, `replace_stringdb_text` | compose — `qm link` merges every Shipment's writes to one table (below), in this Shipment and others |
| `add_*` minting a name (`add_model`, `add_movie`, `add_script`, …) | `KeyedSet` — the same new name twice is a conflict |
| `add_sound` | `KeyedSet` on the bank name and on each cue — the same bank or cue name added twice is a conflict |
| `replace_sound_bank` | `Exclusive` on the bank's entry (`<bank>` or `<bank>.<language>`) and on every cue it declares |
| `replace_sound_cue` | `Exclusive` on the cue; replacements of different cues of one bank compose ([below](#sound-banks-are-merged)) |
| `native_hook`, `place_file`, `add_runtime_dll` file names | `Exclusive` per game-folder path, **compared lowercased** (Windows file names are case-insensitive) |
| `native_hook` `touches` | `Exclusive` per hooked address or symbol, exactly as spelled (see the Code layer) |
| `raw` | `Exclusive` on every declared target |

Within **one** Shipment, two contributions claiming one target in any class but an append are
**M0120**: only one of them can take effect.

A Shipment can also declare conflicts outright: `load.conflicts` names a Shipment, optionally within
a version range (`- { shipment: other-mod, version: "<2" }`). An installed match is **M0206**.

### String tables are merged

A Shipment's own build applies all of its `edit_stringdb` / `add_stringdb_keys` /
`replace_stringdb_text` contributions to one table **in contribution order**, each against the table
as edited so far, and ships the result as one copy of the table: an edit of a key the table (so far)
does not have, or an addition of one it has, is an error. So a Shipment can replace, by text, what its
own earlier `edit_stringdb` wrote.

Each Shipment's overlay carries a whole edited copy of its table, so installed together the last
mounted would silently drop the others' edits. `qm link` therefore merges every installed Shipment's
writes to one table into a single link-owned table — with the same code — applied in load order with
the later write winning:

- `edit_stringdb` / `add_stringdb_keys` go by key hash — a key that exists is overwritten, one that
  does not is added;
- `replace_stringdb_text` matches text in the table **as merged so far**, so it sees every earlier
  write. A pair that matches nothing there is an error naming the Shipment, the table and the text —
  in `qm link`, and in the Shipment's own build.

`replace_stringdb_text`'s `pairs:` file has one `old<TAB>new` pair per line; a line starting with `#`
is a comment and blank lines are skipped. The text is taken exactly as written (nothing is trimmed or
unescaped), so it can contain spaces, `:` and `=`. A line with no tab, more than one tab, or an empty
old text is an error naming the file and line.

One Shipment may fix a table by key and by text. The link WAD carries the merged table, and the load
plan's `link_block_paths` names it so a deploy step drops the per-Shipment copies.

### Sound cues are claimed by guid and language

A sound contribution claims each cue as `SoundCue { guid, language }`: `guid` is `m2` of the cue's
name, and `language` is the declared language of a `vo_*` override (none otherwise). Each language's
`vo_*` banks are separate entries (`<bank>.<language>`), so claims in different languages never
conflict.

| kind | claims | intent | class |
|---|---|---|---|
| `add_sound` | the bank (an asset) and each cue | additive | `KeyedSet` |
| `replace_sound_bank` | the bank's entry (an asset) and every declared cue | replace | `Exclusive` |
| `replace_sound_cue` | the cue | replace | `Exclusive` |

An added cue name is a key across the set because FindCue answers from the first loaded table that
has the guid (`FUN_00835a70`): of two banks adding one cue name, one is never heard. A replaced cue
has one winner in the table the game loads.

Each sound kind also claims the scripts its loaders live in, additive, for each session it loads in
(an `add_sound`'s `load_in`; for an override, the sessions retail loads its bank in): gameplay claims
`wifpmcinterior` and `mrxsoundbootstrap` in `vz.wad`; the front end claims `qm_shell_modloader` and
`mrxsound` in `shell.wad`. A script claim names its level, so the front end's `mrxsound` is not
`vz.wad`'s. Any number of sound Shipments share the loaders; a `replace_lua` of a host a sound
Shipment loads through (`replace_lua wifpmcinterior` beside a `ui_hud` override) is a conflict.

### Sound banks are merged

Each Shipment's build ships a whole soundbank per bank it overrides, and of several copies of one
bank the last mounted is the one the game reads. `qm link` merges every bank a
`replace_sound_cue` in the set targets: per carrier (the overlay, the shell patch, each language
patch), one soundbank at `blocks\VZ\mod_<entry hash>.block`, starting from the set's
`replace_sound_bank` of that entry when there is one and the game's bank otherwise, with every
`replace_sound_cue` applied in load order. The load plan's `link_block_paths` lists these blocks,
so a deploy step drops the per-Shipment copies. The link writes them to
`zz-quartermaster-link.wad` (overlay), `zz-quartermaster-link.shell-patch.wad` (shell patch) and
`language_patch/<language>.wad` (language patch), each recorded in `placement.json`.

The override wavebanks are not merged: each is named for its Shipment, so they never collide.

The link also bakes one loader per session over the set: `qm_modloader` in `scripts_vz`, and
`qm_shell_modloader` in `shell.wad`'s scripts block, which it writes to
`zz-quartermaster-link.shell-patch.wad` with the merged banks. `link_block_paths` always lists
`blocks\Shell\resident_P000_Q3.block` after the `vz.wad` scripts blocks, so a deploy step drops each
Shipment's own copy of the front end's scripts block and keeps the link's.

### Write-sets and read-sets

A claim is not only a write. Shipment A can *read* something Shipment B provides; uninstall B and A's
contribution evaporates with no error anywhere. So a blast radius records both, and a read with no
writer is a finding at deploy rather than a mystery later.

`donor:` is a read — it is borrowed, never written.

### Why `patch_lua` takes an append, not a script

Scripts do not load individually. All 114 live in one block, so editing one means re-emitting all of
them — and two Shipments that each ship their own copy of that block cannot both win. The last one
installed erases the other, silently.

You therefore declare an **append**, and `qm link` composes every installed Shipment's appends onto
the base script, compiles once, and emits a single WAD mounted last. This works for **any** script:
there is no list of scripts that may be patched. A wholesale `replace_lua` cannot compose — an append
to it would land on source that is no longer there — so it conflicts with any other writer to that
script.

The order the appends are concatenated in is the **load order**: a Shipment always comes after the
Shipments it `requires`, and the order the installer lists them in breaks ties. The same order
decides everything else ordered in a link — which of two string edits wins, the order `add_script`
modules are minted. A stable order matters more than it looks: a saved costume is stored as a
*position* in the outfit list, so if the order changed the indices, reinstalling mods would silently
re-dress the player — or leave a saved index pointing at nothing and wedge the load.

`add_script` modules and `import`: at link time `qm link` warns (**M0209**, a warning that never
fails the link) about a **literal** `import("x")` / `import('x')` whose `x` is no shipped script, no
`add_script` in the set and no module qm mints. **Dynamic imports are not checked**:
`dynamic_import(...)`, `import(<expression>)`, a concatenated name (`import("a" .. b)`), the
`import "x"` call without parentheses, and names reached through data such as a task's
`sModuleName` all resolve at runtime, where the linker cannot see them.

The same reasoning is why the availability count is derived from the final list length instead of
written by each Shipment. Two mods that each append one outfit and each hard-code "one more outfit"
produce the same number: both outfits are in the WAD, in the table, and one is unreachable.

## The Code layer

Three kinds place native-code files in the game folder, and none takes a path: the destination is a
closed set of names, and the file name comes from the source file.

- **`native_hook`** places one prebuilt `.asi` plugin in `scripts/`, where `pmc_bb.dll` loads it on
  retail. M0160 rejects attaching one to a `reimpl` target, where the loader does not exist, and
  M0161 a hook with neither a plugin nor a symbol.
- **`place_file`** places a companion file (an `.ini` beside a plugin, a Lua framework's `.lua`
  files) under a destination name: `game_root`, `scripts`, `plugins`, `update`, `on_boot`, `on_load`,
  `on_key`. It refuses `.asi`, `.wad`, `.exe` and `.dll`.
- **`add_runtime_dll`** places one runtime DLL — a library other plugins import by name — in the game
  root, the directory Windows searches first:

  ```yaml
  - kind: add_runtime_dll
    dll: src/my-runtime.dll
  ```

  The file must be named **`<shipment.name>.dll`** (compared case-insensitively), so a runtime
  Shipment ships exactly one DLL, named after itself, and two Shipments can never ship one name. Its
  stem must not be on the deny list — `pmc_bb` (the loader), `cruise` (its sidecar), `dxwrapper`,
  `binkw32` — which is also why those are reserved Shipment names (M0211).

**M0162** refuses a file name no Shipment may write (any of the rules above). **M0178** refuses a
plugin or runtime DLL the game could not load: not an i386 PE image with the DLL flag, since
`Mercenaries2.exe` is a 32-bit process and `LoadLibrary` refuses anything else.

**A prebuilt ASI or DLL is arbitrary native code.** The Quartermaster does not compile it and does not
read its import table. What it records is *which bytes* were placed: every placement's sha256 is in
`placement.json` and the load plan. That is **integrity, not authenticity** — it proves the file is
the one that was built, not that it is safe. Treat installing one the way you would treat running
any downloaded executable. A plugin that needs another Shipment's DLL must say so in
`load.requires`; nothing checks its imports for it, and a missing DLL is a runtime failure.

### `native_hook`

```yaml
  - kind: native_hook
    target: retail
    plugin: src/my_hook.asi
    touches: ["0x004CF340", "0x004CF400"]
    signature_guard:
      "0x004CF340": "55 8B EC"
      "0x004CF400": "53 56 57"
```

`plugin` is the `.asi`, placed in `scripts/`; `symbol` names a detour instead of (or as well as) a
plugin, and one of the two is required (M0161). `touches` is the list of hooks the plugin installs,
claimed `Exclusive` ([spelling below](#touches-how-hooks-are-spelled)).

`signature_guard` records, per touched address, the prologue bytes the plugin expects to find there
— the check a well-behaved plugin makes at load time before patching, so it leaves an exe that has
shifted under it alone. **M0199** checks the guards: a guard for an address the hook does not
`touch`, or a value that is not space-separated hex bytes, is an error; once some addresses are
guarded, a touched address left unguarded is a warning; and with the game in hand
(`qm lint --with-game`, and during `qm build`) a guard whose bytes do not match `Mercenaries2.exe`
at that address is a warning — the local exe may be a different build than the hook targets.
Declaring no guards at all is allowed.

### `touches`: how hooks are spelled

`native_hook` `touches` are claimed `Exclusive`, and a collision is a hard error — no load order
fixes two plugins hooking one function. The claim is on the exact string, so **two plugins collide
only if they spell the same hook the same way**. Spell each hook kind one way:

| hook kind | spelling | example |
|---|---|---|
| game code, at a fixed address | `0xVVVVVVVV`, the virtual address in that EXE build | `0x004CF340` |
| an exported Windows API function | `module!function`, the module lowercased and without `.dll` | `ws2_32!connect` |
| a COM method | `Interface::Method` | `IDirect3DDevice9::EndScene` |
| a Lua binding's C function | `Table.Function`, declared next to its `0xVVVVVVVV` | `Player.SetCash` |

Declare each hook **by its symbol name** (`luaB_type`, `ws2_32!connect`,
`IDirect3DDevice9::EndScene`) **and**, where it has fixed addresses, **by the VA for every EXE build
the plugin supports** — so a plugin that picks its addresses per build declares each of them.

### Dependencies

`load.requires` declares what must be installed for a Shipment to work. **Every dependency is a
Shipment**, runtimes included; there is no other kind. Three forms:

```yaml
load:
  requires:
    - lua-bridge                                     # that Shipment, any version
    - { shipment: lua-bridge, version: "^1.0.0" }    # that Shipment, within a semver range
    - { capability: widescreen }                     # any Shipment that `provides: [widescreen]`
```

Before a build, `qm preflight` (and `qm link`) checks the whole installed set: a requirement with no
provider, or a provider outside the range, is **M0204**; two Shipments with one name are **M0203**.
A requirement also orders the load: a Shipment loads after the Shipments it requires (a cycle is
**M0174**).

Ranges are semver ranges with Cargo's grammar (**M0172** rejects one that does not parse). Note the
caret on a `0.x` version: **`^0.6` means `>=0.6.0, <0.7.0`**, so it excludes `0.7.0`. Write
`">=0.6, <1"` when you mean "any 0.x from 0.6". A Shipment naming itself in `requires` or `conflicts`
is **M0173**. `shipment.quartermaster`, when present, is a range the running qm must satisfy
(**M0210**).

**Removed forms.** `{ name, version }` is not a requirement form; validation says to write
`{ shipment: <name>, version: <range> }`. The external pin `{ url, sha256 }` is gone and does not
parse, and with it M0170 and M0171: a Shipment never installs a file from a URL — a plugin you depend
on is required as the Shipment that ships it. `load.after` / `load.before` are gone too; the load
order comes from `requires`.

## Limits

- `shipment.name` — at most 64 characters, `^[a-z0-9]+(-[a-z0-9]+)*$`. It becomes a filename.
- A patch WAD's header region — the block index, asset table and path list — shares the 2 MB below
  the payload region at `0x208000`. Overflowing it writes the path list into the payload (M0181).
- Every block must declare a decompressed size at least as large as it actually inflates to. The
  engine sizes its buffer from that number, so under-declaring overruns the heap (M0002).

The last two are properties of the built WAD rather than of your manifest, and `qm` checks them
against the artifact before writing it to disk.

## What the checks mean

```
[M0007] warning: pmc_hum_example is a STREAMED texture … — see https://…
```

| severity | effect |
|---|---|
| `info` / `warning` | printed; the build proceeds |
| `error` | the build fails |
| `HANG` | the build fails — this class freezes the game with no message at all |

Builds are gated on the **exit code**, never on a printed count, so a script that discards output
still cannot ship a broken Shipment.

`qm rules` lists every rule, including the ones that are known but **not yet implemented**. Those are
listed on purpose: a linter that silently omits its most dangerous checks reads as a clean bill of
health.

The sound and language rules below are errors. M0214–M0217 and M0221 need no game; M0218–M0220
need the game stack and run in `qm lint --with-game` and in `qm build`.

### M0214

**A sound cue's WAV is not uncompressed 16-bit mono or stereo PCM.** Fires when the strict reader
(`mercs2_audio::wav::read_pcm16_wav`) refuses a cue's `wave`: the file cannot be read, is not
RIFF/WAVE, its format is not 1 (PCM), its bits per sample are not 16, its channels are not 1 or 2,
its rate is 0, its block align is not `channels × 2`, its `data` chunk is empty or ends inside a
frame, it lacks or repeats a `fmt ` or `data` chunk, `data` comes before `fmt `, or its RIFF size
and chunks do not add up to the file. The build reads the file through the same reader.

Fix: export the sound as uncompressed 16-bit PCM WAV, mono or stereo.

### M0215

**A sound bank or cue name the engine cannot reach.** Fires on:

- two cues of one bank whose names hash to one guid — `m2` folds case, so `Click` and `click`
  collide;
- a bank or cue name that is empty, written as a bare `0xHHHHHHHH` hash, or has surrounding
  whitespace (the whitespace is hashed with the name);
- a bank with no cues;
- an `add_sound` bank whose name starts with `vo_`: retail Lua appends the language to such a name
  before loading it (`_GetLocalizedName`, `mrxsoundbanks.lua:80-87`), so the loader would ask for
  `<bank>.<language>` and find nothing.

Fix: give each cue a distinct name, write names as plain trimmed text, declare at least one cue, and
name an added bank without the `vo_` prefix.

### M0216

**A sound bank's `category` is not a category of the game's tree.** A group's category hash must be
one of the 19 categories of the global sounddb's tree
([`audio_code_map.md` §11.3](../reverse_engineer/audio_code_map.md#113-sounddb)). 14 have known
names: `ambience`, `chatter`, `collision`, `explosion`, `foley`, `music`, `Non_Action_Hijack`,
`non_ui`, `sfx`, `source`, `ui`, `vehicle`, `vo`, `weapon`; the other five have no known name, so a
manifest cannot name them.

Fix: use one of the 14 names; the diagnostic suggests the nearest.

### M0217

**A sound override's `language` does not match its bank.** Fires on `language` on a
`replace_sound_bank` / `replace_sound_cue` whose bank is not `vo_*` (the game has one copy of it for
every language), or on no `language` on one whose bank is `vo_*` (each language has its own copy,
`<bank>.<language>`). See [The `language` field](#the-language-field).

Fix: remove `language` from a non-`vo_*` override; name the language on a `vo_*` one.

### M0218

**A sound override's bank or cue is not in the game, or the game never loads the bank.** Fires when
no carrier holds a soundbank under the override's entry name — the carriers being the game stack
(`vz.wad` and the declared languages' WADs) and `shell.wad` beside it — when no carrier that holds
it loads it ([Where a sound override ships](#where-a-sound-override-ships)), or when a
`replace_sound_cue`'s cue is not in that bank (a cue the same Shipment's `replace_sound_bank`
declares for the bank counts as in it).

Fix: write the bank name exactly as the game's Lua loads it (`ui_hud`, `vo_mattias`) and, for a
`vo_*` bank, the right `language`. To add a cue the bank does not have, use
[`add_sound`](#add_sound).

### M0219

**An `add_language` base has no fonts or font atlases to fork.** Fires when the `base` language
(default `english`) has no fonts `<base>_18` / `<base>_20` or atlases `<base>_18_main` /
`<base>_20_main` in `vz.wad`'s stack or in `shell.wad`, or when the two hold different bytes for
one of them. In the retail install only `english` has them.

Fix: omit `base`, or set it to `english`.

### M0220

**An `add_sound` cue has the name of a cue the game already has.** Fires when an added cue's guid is
routed by a sounddb in the game stack or in any language WAD installed beside `vz.wad` (the running
language's `vo_*` banks load at boot, `mrxsoundbootstrap.lua:219-245`, before the mod loader runs).
FindCue walks the loaded sound tables from the first loaded and answers with the first that has the
guid (`FUN_00835a70`), so the game's cue plays and the added one never does.

Fix: to change the game's cue, use [`replace_sound_cue`](#replace_sound_cue); to add a cue, give it
a new name.

### M0221

**An `add_sound`'s `load_in` is empty or lists a session twice.** `load_in` names the sessions whose
loader loads the bank — `gameplay`, `front_end` — and the bank's block ships to each one's WAD
([`add_sound`](#add_sound)). An empty list loads the bank nowhere.

Fix: list where the bank plays, each session once: `[gameplay]`, `[front_end]` or
`[gameplay, front_end]`.

[template]: https://github.com/Mercenaries-Fan-Build/mercs2-shipment-template
