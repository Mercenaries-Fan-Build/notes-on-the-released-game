# FX live test: new world templates and effect placement

This is what to run on Windows to settle the questions the static reading of the game cannot:

1. Is a `worldentity` container shipped in a patch block processed at all, and does a template
   appended to it become spawnable by name?
2. Does the engine accept a template key derived from its name, or only one next to the existing
   keys?
3. Does an effect replacement take effect when the patch ships the whole effects block, or when it
   ships the one effect as its own block?

The archives are built by `fx_livegate` (`mercs2_quartermaster/examples/fx_livegate.rs`, in the qm
workspace), which reads the game only through `.mercs2-local.toml`. The container format and every
static finding these tests start from are in
[`../worldentity_container_format.md`](../worldentity_container_format.md).

---

## 1. The archives

Each is a Shipment directory (`manifest.yaml` + `src/`) that Modkit installs. The `build/` folder
inside each is the overlay `fx_livegate` built and checked with qm; Modkit builds its own.

| Archive | What it ships | Claims |
|---|---|---|
| `g0` | the retail `worldentity` `0x50075B3B`, re-written by the codec (identical bytes), as a one-entry `raw` block | `0x50075B3B` |
| `g1` | the same container with template `qm_gate_c4` appended under `0x8D9E11CB` (`0x8` + the low 28 bits of the name hash `0xAD9E11CB`) | `0x50075B3B` |
| `g2` | the same template under `0x8000B3C5`, the highest existing `0x8` key + 1 | `0x50075B3B` |
| `fx_a` | the whole effects block (314 effects, 46 meshes), `global_explosion_c4` recoloured magenta with its frames on the texture `qm_gate_magenta_disc`, plus that texture | 360 assets + the texture |
| `fx_b` | only the magenta `global_explosion_c4`, as a one-entry block, plus the texture | `0x41B4326E` + the texture |

`qm_gate_c4` is declared field by field through the template author form, with the values the
retail C4 template `global_particle_explosion_c4` (`0x80008028`) holds: `EffectTemplate`,
`HibernationControl`, `RedEffectComponent` (effect `global_explosion_c4`), `SoundEffect`. A working
spawn of it looks and sounds like a C4 explosion.

The magenta effect keeps every attribute; only each `COLR` key's first three bytes become
`FF 00 FF` (the fourth is kept) and every `TEXT` frame becomes the 64×64 magenta disc.

**Why each worldentity archive is a one-entry block, not the resident block at its own path.** No
Shipment can carry an edited `blocks\VZ\resident_P000_Q3.block` into the installed patch:

* `raw` ships a block at `blocks\VZ\mod_<first entry hash>.block`, never at a base path
  (`mercs2_quartermaster/src/build.rs`, the `Contribution::Raw` lowering).
* Modkit drops every per-Shipment copy of the blocks the load plan lists as link-owned. That list
  always includes the resident block (`build::link_block_paths` chains `link::SCRIPT_BLOCKS`
  unconditionally; Modkit `commands/shipment.rs` `collapse` / `is_link_owned`).
* `qm link` rebuilds the resident block from the game's own copy plus Lua edits, never from a
  Shipment (`build.rs`, `load_script_blocks(game, link::SCRIPT_BLOCKS, …)`).

**When a `g` archive reaches `vz-patch.wad`.** Modkit keeps the `mod_50075b3b` block (it is not
link-owned) and resolves claims by asset hash (`models/claim.rs` `resolve`). `qm link` emits the
resident block only when some installed Shipment patches a script that lives in it (`add_script`,
`add_ui` and the mod loader land in `scripts_vz`). When it does, it copies every base ASET row,
including the by-hash row for `0x50075B3B`, and as the last group it overrides the `g` archive
completely. **So install no Shipment that patches a resident script during these runs**, and check
the next step.

## 2. Before the runs

1. Back up the game folder's `data/vz-patch.wad` and the save you will load.
2. In Modkit, the installed set for each run is: the Shipments `tools/lua_repl.py` needs (the Lua
   bridge), plus the archives the run names below. Nothing else.
3. After Modkit builds, open its build report. The archive's outcome must be **Applied**. If it says
   **Overridden**, a link-owned block took its claim; record that and stop.
4. Start the game, load the save in the open world, stand in an open area.
5. Check the bridge: `python tools/lua_repl.py --probe`.

Every command below is `python tools/lua_repl.py --code '<code>'` from the Ess repo. Record each
printed result exactly.

## 3. The runs

Run them in order. Each is: install in Modkit, build, check the outcome (§2.3), launch, run the
commands, quit.

### Run 1: `g0` + `fx_a`

```lua
-- R1.1 position
local x,y,z = Object.GetPosition(Player.GetLocalCharacter()); return x..","..y..","..z
-- R1.2 the name lookup, for the retail template and for the new name
return tostring(Pg.GetGuidByName("global_particle_explosion_c4")) .. " | " .. tostring(Pg.GetGuidByName("qm_gate_c4"))
-- R1.3 spawn the retail C4 template 15 m away: look for MAGENTA (fx_a)
local x,y,z = Object.GetPosition(Player.GetLocalCharacter()); return tostring(Pg.Spawn("global_particle_explosion_c4", x+15, y, z))
```

Then detonate a real C4 charge and watch its explosion colour.

### Run 2: `g1` + `fx_b`

```lua
-- R2.1 the name lookup
return tostring(Pg.GetGuidByName("global_particle_explosion_c4")) .. " | " .. tostring(Pg.GetGuidByName("qm_gate_c4"))
-- R2.2 the retail C4 template: look for MAGENTA (fx_b)
local x,y,z = Object.GetPosition(Player.GetLocalCharacter()); return tostring(Pg.Spawn("global_particle_explosion_c4", x+15, y, z))
-- R2.3 the new template
local x,y,z = Object.GetPosition(Player.GetLocalCharacter()); return tostring(Pg.Spawn("qm_gate_c4", x+15, y, z))
-- R2.4 a Humvee to emit from
local x,y,z = Object.GetPosition(Player.GetLocalCharacter()); qmHumvee = Pg.Spawn("Humvee (Cargo)", x+12, y, z); return tostring(qmHumvee)
-- R2.5 (wait 1 s: a fresh spawn's hardpoints read nil for ~0.3 s) the hardpoint
return tostring(Object.GetHardpointPosition(qmHumvee, String.GetHash("hp_fx_exhaust_a")))
-- R2.6 StartEmitter with the retail template
ObjectState.StartEmitter(qmHumvee, String.GetHash("hp_fx_exhaust_a"), String.GetHash("global_particle_explosion_c4")); return "sent"
-- R2.7 StartEmitter with the new template
ObjectState.StartEmitter(qmHumvee, String.GetHash("hp_fx_exhaust_a"), String.GetHash("qm_gate_c4")); return "sent"
```

Then detonate a real C4 charge and watch its explosion colour.

### Run 3: `g2`

R2.1, R2.3, R2.4, R2.5 and R2.7 again.

### The control, last in each run

`Pg.Spawn` of a name no template has. It is last because its outcome is not recorded anywhere: an
empty name hard-crashes the engine with a null asset (Ess `src/49_ui_menu.lua:79`), and a missing
name may do the same. Save first.

```lua
local x,y,z = Object.GetPosition(Player.GetLocalCharacter()); return tostring(Pg.Spawn("qm_gate_no_such_template", x+15, y, z))
```

Its result (a value, `nil`, an error, or a crash) is the miss signature to compare R2.3 and R2.7
with.

## 4. Verdicts

| Observation | Verdict |
|---|---|
| Run 1: the game loads and R1.3 spawns a normal C4 explosion | A `worldentity` re-shipped in a patch block is harmless. |
| Run 1: the game fails to load or crashes with `g0` installed | Re-shipping the container is not safe as packaged; stop and report the point of failure. |
| R2.1 / R2.3 resolve `qm_gate_c4` and R2.3 shows a C4 explosion | The patch block's container is processed and an appended template is spawnable under a name-derived key. The one-entry block is the shipping shape. |
| R2.3 gives the control's miss signature, Run 3's R2.3 a C4 explosion | Processed, but the name-derived key is refused; keys must continue the existing range. |
| R2.3 and Run 3's R2.3 both give the miss signature | The patch block's container is not processed (the "inert" packaging); confirm with §5. |
| R2.7 shows the explosion at the exhaust | `StartEmitter` resolves a new template like a retail one. |
| R2.6 works and R2.7 does not, while R2.3 works | `StartEmitter`'s lookup differs from `Pg.Spawn`'s; record both results. |
| Magenta in Run 1 and not in Run 2 | Effects ship as the whole composed effects block. |
| Magenta in Run 2 and not in Run 1 | Effects ship one per block. |
| Magenta in both | Either works; the per-effect block is smaller. |
| Magenta in neither, normal colour | The effect replacement is not picked up as packaged. |
| Magenta tint with a square or missing sprite | The colour change works and the disc texture is not resolved. |

## 5. x32dbg: is the shipped container processed?

For the unpacked image (base `0x00400000`). Log, don't break, unless a step says so.

| Address | What | Condition / log |
|---|---|---|
| `0x004646B0` | block dispatch, calls `FUN_00654940` per block | count hits while loading |
| `0x00654940` | the `worldentity` loader | count hits: two when both the resident block's and the patch block's containers are processed |
| `0x006569B0` | `Name` deserializer, entry | `[esp+4] == 0x8D9E11CB` (Run 2) or `0x8000B3C5` (Run 3): the new template's name is being registered |
| `0x00649180` | container insert, entry | `[esp+4] == 0xDF6B88 && [esp+8] == <key>`: the `Name` record is inserted |
| `0x00672F60` | template lookup by name hash | log `eax`, which `FUN_00672F70` copies into its cursor as the key (that it is the name hash at this entry is inferred); `pandemic_hash_m2("qm_gate_c4") = 0xAD9E11CB` |
| `0x0067306E` / `0x0067303E` | its two returns: found (`eax` = key) / not found (`eax` = 0) | log `eax` |

A hit at `0x006569B0` with the new key means the patch block's container is processed. A lookup of
`0xAD9E11CB` that returns 0 after that means the record did not make it into the name index.

## 6. Reporting

For each command: the run, the code, the printed result. For each colour check: what was seen. For
any crash: the address and the last command. The archives' sha256 are in
`fx_livegate_report.txt` beside them.
