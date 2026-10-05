# FX live gate: effects and templates through `qm link`

Two parts: what the live runs of 2026-10-04 showed (§1), and the retest of `add_fx` and `replace_fx`
as `qm` ships them (§2). The container formats are in
[`../effect_container_format.md`](../effect_container_format.md) and
[`../worldentity_container_format.md`](../worldentity_container_format.md); the kinds are in
[`manifest_format.md`](manifest_format.md#add_fx).

---

## 1. Outcomes, 2026-10-04

The game ran under Wine on macOS, installed through Modkit, driven over the Lua bridge
(`tools/lua_repl.py` in the Ess repo). Four archives were used, each a `raw` Shipment:

| Archive | What it shipped |
|---|---|
| G0 | the retail `worldentity` `0x50075B3B`, re-written by the codec (identical bytes), as a one-entry block |
| G1 | the same container with the template `qm_gate_c4` appended under its derived key `0x8D9E11CB` (`0x8` + the low 28 bits of `pandemic_hash_m2("qm_gate_c4")` = `0xAD9E11CB`) |
| FX-A | the whole effects block (314 effects, 46 models), `global_explosion_c4` recoloured magenta |
| FX-B | the magenta `global_explosion_c4` alone, as a one-entry block |

`qm_gate_c4` was declared field by field through the template form with the values of the retail C4
template `global_particle_explosion_c4` (`0x80008028`), so a working spawn of it is a C4 explosion.

### Run 1: G0 + FX-A

- A placed C4 charge exploded magenta.
- `Pg.Spawn("global_particle_explosion_c4")` exploded magenta.
- `ObjectState.StartEmitter` on a Monster Truck's `hp_fx_exhaust_a` with the C4 template fired it.
- "Humvee (Cargo)" spawned as a prop without physics.
- `Pg.GetGuidByName`: the retail C4 template returned `80008028`; a name no template has returned
  `nil`.

### Run 2: G1 + FX-B

- `Pg.GetGuidByName("qm_gate_c4")` returned `8D9E11CB`.
- Spawned templates, `qm_gate_c4` and the retail C4 alike, played their sound with no visual.
- A placed C4 charge exploded with the retail look, not magenta.

### Run 3: G1 + FX-A

- `Pg.Spawn("qm_gate_c4")` showed the C4 explosion.
- `ObjectState.StartEmitter` on the Monster Truck's `hp_fx_exhaust_a` with `qm_gate_c4` fired it.

### What the runs settle

| Question | Answer |
|---|---|
| Is a `worldentity` shipped in a patch block processed? | Yes: G1's appended template resolved by name (Run 2) and spawned (Run 3). |
| Does a template key derived from its name work? | Yes: `0x8D9E11CB` resolved, spawned, and fired from `StartEmitter`. |
| Does `StartEmitter` resolve a new template like a retail one? | Yes (Run 3). |
| Does an effect ship as the whole effects block? | Yes: the whole block recoloured the C4 explosion (Run 1, Run 3). |
| Does an effect ship as its own one-entry block? | No: with FX-B, spawned effects lost their visuals and the charge kept the retail look (Run 2). That the lone-effect block caused it is SPECULATIVE; the cause was not traced. |

`qm` ships effects only as the whole effects block at its own path, and templates only inside the
resident block's `worldentity`, both merged across the installed set by `qm link`
([`manifest_format.md`](manifest_format.md#effects-and-templates-are-merged)).

---

## 2. Retest: `qm-fx-a` and `qm-fx-b`

The two Shipments are fixtures of the qm workspace, `crates/mercs2_quartermaster/tests/fixtures/fx/`:

| Shipment | Contributions |
|---|---|
| `qm-fx-a` | `add_fx` `qm_fx_cyan_burst` (a cyan one-emitter burst) with template `qm_cyan_burst`; `replace_fx` of `global_explosion_c4`, every emitter magenta |
| `qm-fx-b` | `add_fx` `qm_fx_green_burst` (a green one-emitter burst) with template `qm_green_burst`; `replace_fx` of the effect the template `global_particle_fire_carhood` starts, every emitter yellow |

Each template carries the retail C4 template's components (`EffectTemplate`, `HibernationControl`,
`RedEffectComponent`, `SoundEffect`), its `RedEffectComponent` naming the Shipment's own effect, so a
spawn of it plays the C4 sound with the Shipment's burst. The bursts draw the C4 effect's own frames,
which are records of the game's `fxdict`.

| Template | Derived key |
|---|---|
| `qm_cyan_burst` | `0x899E7D78` |
| `qm_green_burst` | `0x8E53AD44` |

### 2.1 Install

With Modkit's `headless_deploy` (`src-tauri/examples/headless_deploy.rs`), while the game, its Wine
prefix and the Modkit app are closed:

1. `snapshot --real --game-root <R> --out <S>.json`, where `<R>` is the game folder.
2. `install --real --game-root <R> --qm <qm> --rows <rows>.json --shipment <fixtures>/qm-fx-a`,
   where `<rows>.json` is the installed set to keep (the Lua bridge Shipments the session needs) and
   `<fixtures>` is `crates/mercs2_quartermaster/tests/fixtures/fx`.
3. `install` again with `--shipment <fixtures>/qm-fx-b` and the rows of step 2 plus `qm-fx-a`.

Each install's report lists every Shipment's outcome. All must be **Applied**, with no claim
conflict. The final `vz-patch.wad` carries one `blocks\VZ\effects_P000_Q3.block` and one
`blocks\VZ\resident_P000_Q3.block`, both from the link group.

### 2.2 In the game

The user launches the game, loads the save in the open world and stands in the open. Each command is
`python tools/lua_repl.py --code '<code>'` from the Ess repo; record each printed result.

```lua
-- names: each new template resolves under its derived key; a missing name is nil
return tostring(Pg.GetGuidByName("qm_cyan_burst")) .. " | " .. tostring(Pg.GetGuidByName("qm_green_burst")) .. " | " .. tostring(Pg.GetGuidByName("qm_fx_no_such_template"))
-- expect: 899E7D78 | 8E53AD44 | nil

-- spawns, 15 m from the player: cyan, green, magenta, yellow
local x,y,z = Object.GetPosition(Player.GetLocalCharacter()); return tostring(Pg.Spawn("qm_cyan_burst", x+15, y, z))
local x,y,z = Object.GetPosition(Player.GetLocalCharacter()); return tostring(Pg.Spawn("qm_green_burst", x+15, y, z))
local x,y,z = Object.GetPosition(Player.GetLocalCharacter()); return tostring(Pg.Spawn("global_particle_explosion_c4", x+15, y, z))
local x,y,z = Object.GetPosition(Player.GetLocalCharacter()); return tostring(Pg.Spawn("global_particle_fire_carhood", x+15, y, z))
```

`Pg.Spawn` takes only names `GetGuidByName` resolved: what a spawn of a name no template has does
is not recorded, and an empty name crashes the engine (Ess `src/49_ui_menu.lua:79`).

Then place and detonate a C4 charge: it explodes **magenta**.

Then the emitter:

```lua
-- a Monster Truck (template "Monster Truck", 0x80006C99) to emit from
local x,y,z = Object.GetPosition(Player.GetLocalCharacter()); qmTruck = Pg.Spawn("Monster Truck", x+12, y, z); return tostring(qmTruck)
-- (wait a second: a fresh spawn's hardpoints read nil for ~0.3 s)
return tostring(Object.GetHardpointPosition(qmTruck, String.GetHash("hp_fx_exhaust_a")))
ObjectState.StartEmitter(qmTruck, String.GetHash("hp_fx_exhaust_a"), String.GetHash("qm_cyan_burst")); return "sent"
```

The cyan burst plays at the exhaust.

| Observation | Meaning |
|---|---|
| both names resolve to their keys, the missing one is `nil` | `qm link`'s resident block carries both Shipments' templates |
| cyan and green bursts | each added effect is in the effects block and its template starts it |
| magenta C4, spawned and placed | `qm-fx-a`'s edit of a game effect, named directly |
| yellow car-hood fire | `qm-fx-b`'s edit, reached through a template |
| cyan burst at the exhaust | `StartEmitter` resolves an added template |

### 2.3 With a script Shipment

Uninstall both (§2.4), then repeat §2.1 with `/Volumes/Projects/mercs2-unofficial-patch` in the rows
and `qm-fx-a`, `qm-fx-b` installed after it. Every outcome is **Applied**. The resident block in the
final `vz-patch.wad` is link's and carries the unofficial patch's linked `mrxplayer` and both
templates; `headless_deploy blocks --wad <R>/data/vz-patch.wad --overlay <link WAD>` reports each of
the link WAD's blocks as byte-identical in the final WAD. Then run §2.2 again.

### 2.4 Uninstall

`uninstall --real --game-root <R> --qm <qm> --rows <rows>.json` with the rows of the set before the
fixtures, then `verify --real --game-root <R> --snapshot <S>.json`: the game folder matches the
snapshot.

### 2.5 Reporting

For each command, the printed result; for each colour, what was seen; for any crash, the last
command. Record each install's outcomes and the sha256 of the final `vz-patch.wad`.
