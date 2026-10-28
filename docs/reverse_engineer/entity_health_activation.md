# Entity health at activation — RuntimeHealth and RuntimeNodeHealth (PC v1.0)

Decoded and adversarially audited 2026-10-21. Code read from the mid-mission and flying-winch capture
images; Xbox retail twin `FUN_8222d850` (`xenon_retail_decomp_named.c` ~161830). Live: all 658
RuntimeHealth and all 652 RuntimeNodeHealth tables (1,090 nodes) of the flying-winch capture match
the formulas below against the shipped worldentity records. Grades: PROVEN unless marked.

## When

At **activation**, not at creation and not on first damage: the ModelName component listener's
complete slot (`+0x18` of vtable `0xBCC7B4`) `FUN_006696a0` runs when an entity's activation
completes (`FUN_004F7C6A`, SceneObject state 1 → 2). It bails when the entity's render object already
exists. Teardown is the same listener's `+0x1C` `FUN_006693b0` on deactivation.

## Health source

`hp` = the `Health` component's `TestFloat` (f32 `+0x00`; schema `Health` v81: `+0 f32 TestFloat`, `+4`
bits Invincible / Unkillable / UseNodeHealthInHud), looked up **by the entity's template**
(`FUN_006654b0` = `SceneObject+0x14` = `Transform.Parent`), then that template's template — the
entity's own `Health` record is never read (`0x4CFEEA–0x4CFEFE`, `0x66990E–0x66991B`). No record →
`hp = 100.0` (`DAT_00B92870`).

## Path A — the model has a state-machine descriptor (model `+0xC4` non-null): `FUN_004cfed0`

- `dead = SceneObject+0x1A bit0 || hp < 0.01`.
- RuntimeHealth (container `0x017BEF78`, `{f32 max, f32 cur, f32 thr}`):
  - alive: `{hp, hp, thr}` with `thr = (float)TickDamage.DamageThresh` when the template's
    `TickDamage` (v41: `DamageThresh` int, `DAMAGE`, `TickLength`, `NodeName`) has DAMAGE > 0 and
    TickLength > 0, else 0;
  - dead: `{max(hp, 0), 0, 0}`.
- Alive only: the node table (0x58C bytes, `FUN_004d5a10`) inserted into RuntimeNodeHealth
  (`0x017BEFC8`): `NodeHealth` records (v81, 24 B: `NAME` hash, `Health`, `DamagePassThrough`,
  `DamageThreshhold`, `TickThreshold`, `TickDPS`) of the entity then its template
  (`FUN_006499f0` inherit walk, deduplicated by node hash), at most 64; each entry (`FUN_004d5880`)
  `{u32 node hash, u16 max = u16 cur = floor(clamp(Health, 1, 65535)),
  u8 floor(clamp(DamagePassThrough, 0, 1)·255), u8 floor(clamp(DamageThreshhold/max, 0, 1)·255)}`.
  (An entity with `RtDebris` takes a single NodeHealth through `FUN_00649440` — not followed.)

## Path B — no state-machine descriptor but a Health record, and no RuntimeHealth yet

RuntimeHealth `{max(hp,0), clamp(alive ? hp : 0, 0, max), thr}` (`FUN_004d5a60`); no node table.

## Teardown

`FUN_004d07b0` latches `SceneObject+0x1A bit0 = (cur < 0.01)` and drops both components — only
alive/dead survives a hibernate; the next activation rebuilds full health.

## Open

The containers behind the SecuROM-resolved insert sites `0x2475895` (a 4-byte payload) and the
generic container vtable slot-6 inserts; `FUN_005262d0` (Invincible / Unkillable); the player
character carries RuntimeHealth (100, 100, 0) but no node table — consistent with path B, unverified.
