# Hibernation grid and entity activation (PC v1.0)

How retail decides when a placed or spawned entity is awake. Decoded 2026-10-21 from the PC v1.0
code of the `updated-chris-exports` captures (SecuROM slots resolved in the live images) and checked
against all four of them; Xbox twins named where read. Grades: PROVEN unless marked INFERRED.

## 1. SceneObject state

SceneObject (container `0x017C02D8`, stride 28) `+0x18`:

| bits | meaning |
|---|---|
| 0..11 | hibernation-grid block index (`0xFFF` = not in the grid) |
| 12..13 | activation state: 0 asleep, 1 waking, 2 awake |
| 14 | priority-activation flag (copied into the pending record) |
| 15 | "static" (selects the radius formula, §2) |

Only the HibernationControl component listener (vtable `0xBCC9AC`, registered at `0x66F470`,
listener index 3) changes the state: begin `+0xC` `0x66AA60` → 1, complete `+0x18` `0x66AA90` → 2,
deactivate `+0x1C` `0x66AAC0` → 0. (Whole-record stores through the SceneObject setter
`0x6658B0`/`0x6658C0` rewrite the bits with the copied value for an existing entity, 0 for a new
one; the Transform reader stores `0x0FFF` at load.) Xbox retail twins `FUN_823fef50` / `…efa8` /
`…f000` write the same field (bits 2–3 on big-endian).

## 2. Registration

The SceneObject container's listener (vtable `0xBB3824`, installed at `0x51668E`): add `+4`
`0x518120` → `FUN_00516280` (register); change `+8` `0x518140` → `FUN_00515F60` + `FUN_00516F00`
(re-cell a moved entity, only when registered); remove `+0xC` `0x5181B0`.

`FUN_00516280(entity)`:
- returns early for an entity that is the attached child (`key2`) of a `RuntimePhysicalLink` with an
  owner — attached children are never in the grid (§6);
- `static` = NOT (TerrainObject `0x17BEA78` or LowResTerrainObject `0x17BEB68` or SceneObject `+0x1A`
  bit2) — "static" does not mean "does not move". For a placed entity bit2 is the Transform record's
  trailing u16 (`+0x28`) bit 9: the Transform reader `FUN_0063D7C0` (`0x63D886..0x63D8EE`) writes
  `+0x1A` = bit 9 → bit 2, bits 0..3 → bits 4..7, and `+0x1B` = `0x40 | bit10<<5 | bit8<<4 | bits 7..4`;
  for a spawn it is the spawn worker `FUN_00673070`'s 4th argument (a flag, or the template's
  NetCategoryInfo bit9). With it, every placed row of the four captures has the static bit its shipped
  records give;
- `dist0` = the entity's own `HibernationControl.Distance`, else its template's (`Transform.Parent`),
  else 100; `d1..d3` = `Q2Distance` / `Q1Distance` / `Q0Distance` (defaults 160 / 60 / 20);
- radius `r14`:
  - static: `cvtt(1.2 × min([0xD1BF34]·dist0, max(dist0, [0x1175DC4]))) & 0x3FFF` (`0x516C2C..0x516C5E`);
  - non-static: `min(0x3FFF, trunc(dist0 × [0x1175DC8]))`;
  - with `k` = `min(scale, 1)` (config `hibernation`: 1.0 single-player, 0.5 multiplayer; INFERRED
    key names), `[0xD1BF34] = 1/k`, `[0x1175DC8] = 1.2/k`, `[0x1175DC4] = minhib/k` (minhib 0 / 50) —
    in single player both are `trunc(1.2·dist0)`;
- `base` = `cvtt(render node +0x90)`, 0 with no node; TerrainObject forces 10000.0 at first
  registration only. The render node (made by the ModelName activation `FUN_006696A0`) holds a
  model-space box at `+0x94..+0xA8` (min, max) and the sphere derived from it: centre `+0x84` =
  (min + max)·0.5, radius `+0x90` = 0.5·sqrt((dz² + dy²) + dx²). With a `TinyGeometryObject`
  component (container `0x17BC458`, tested at `0x669769`) the node is class `0xBAB160`
  (`FUN_00477D10`) and the box is the model's `INFO` box (`INFO +0x04` min, `+0x10` max, copied by
  the INFO reader `FUN_00470D60` into the model resource `+0x1C..+0x30`, sphere at `+0x34..+0x40`),
  never recomputed. Otherwise the node is class `0xBAB0F0` (`FUN_00471FB0`) and the box is recomputed
  from the posed bones at activation (`FUN_004737F0`, `0x66984F`) and by vtable `+0x24`
  (`FUN_004748B0`): the union of each enabled node's HIER box corners (`+0x90` min, `+0x9C` max)
  transformed by its bone matrix (TransformCoord), started at ±65536; then the sphere in f32
  (`0x473D25..0x473DCE`: centre = (max + min)·0.5, radius = sqrt((dz² + dy²) + dx²)·0.5). At
  activation:
  - the bones are the skeleton prefix's reference pose (`FUN_0068FBC0`; the HIER nodes whose `+4`
    flag is set always form a prefix) and HIER local × parent bone for the rest;
  - the root `[+0x270]` is 0;
  - the enables `+0x2A8` are `+0x2A0`, which `FUN_004727B0` builds: every node enabled
    (`[+0x29C]` = 1), then the override list `+0x294` (`{i16 node, u8 flags: bit0 visible, bit1
    inherit}`), then, in index order, a node with no record under an inheriting parent copies the
    parent's enable.
  - The list comes from the model-instance object (MI, `FUN_0068F750`, render `+0x1E4`).
    `FUN_004CFED0` builds the state machine (`FUN_004D3E10`): its bind (`0x2472980`) marks the `SWIT`
    participants controlled, then each switch node, last to first, enters `InitState`
    (`FUN_004D4010`: old state's Exit, new state's Enter).
  - Scripts run through `FUN_004D1B00` (command table `0x016CEED8`). `Show` / `Hide` (`0x4D1BB0` /
    `0x4D1C10`) set or clear "shown" on a controlled node only. `SetState` (`0x4D1C70`) pops node then
    state; the saved-state target `0xCDE0B80F` reads pool `0xDF8B90`, else `PristineState`.
  - A node is visible unless it or an ancestor is controlled and not shown (`FUN_00690AC0`).
  - `FUN_00476BB0` then rebuilds `+0x294`: `[+0x29C]` = vis(node 0), and `(vis, inherit)` for every
    node whose visibility differs from its parent's. Later Show / Hide do not rebuild it.
  - "Shown" starting empty rests on a SecuROM-decrypted bind flag read as 0 (INFERRED).
  - With this rule every placed posed node's `+0x2A0` in the two fresh captures matches (73 / 133).
    The long sessions add destroyed objects and 21 models whose part-variant pair (e.g. under HIER
    `0x206376F6` of `0x6C2E7291`) comes from a second writer (`0x24853D0`, reached through computed
    SecuROM branches; caller not proven).

  `mercs2_formats::render_node` implements this; with it the four captures' posed rows reproduce
  (60 / 62 in the fresh captures, 5,617 / 5,412 of 5,650 / 5,444 in the long ones, the rest moved or
  changed state since). Live boxes are bit-exact only with d3dx9_36's SSE association and the CPU's
  RCPPS / RSQRTSS, which move no captured row. A light's node is made by the LightObject listener
  (vtable `0xBCCEBC`; complete `0x66D630`) from the entity's own LightObject, else its template's:
  - point (type 2, class `0xBACA38`, `FUN_004A7120`): centre 0, radius = max(`+0x18`·s, 0.01);
  - spot (type 3, class `0xBACA80`, `FUN_004A7660`): L = max(`+0x18`·s, 0.01),
    cone = clamp(`+0x24`·c, 0, π), w = L·tan(cone/2), radius = sqrt(L² + w² + w²);
  - s and c are the range and cone scales a LightAnimation (template records only; `+0x00`, `+0x08`)
    applies before the re-cell (listener `0x66D860` → `0x4A80DA`). Later animation never re-cells.

  Every placed light row of the four captures reproduces (71); no spot light was awake in them. A
  low-res terrain tile's node is made by the LowResTerrainObject listener
  (vtable `0xBCCE98`, registered at `0x670C09`; complete `0x66D370`): class `0xBACB38`
  (`FUN_004A8A00`) copies its sphere and box unchanged from the tile resource (type `0x1602815C`,
  the record's payload word 0), which the loader `FUN_004A8690` filled from the tile's `BNDS` (the one
  child of a top-level `GEOM`, 40 bytes: centre xyz, radius, min xyz, max xyz). The radius is the
  stored value; recomputing it from the box differs by 1 ulp on 39 tiles. No placed TerrainObject
  (hi-res tile) has a node in the captures; the TerrainObject listener's complete `0x66CAC0` does build
  one (`0x66CD3A` → `FUN_004AA8A0`, class `0xBACD98`), seen only on runtime keys, whose source is not
  decoded;
- insert (`0x248BB60`) into a 0x1F0-byte cell block (32 slots, overflow chain at `+0x1E8`).

**Re-cell.** `FUN_00516F00`'s only caller is the change listener `0x518140` (`0x51819F`), fired by a
SceneObject container Set (`0x63D9C0`) on an existing key. Its callers are the stream reader
(`0x63D8FF`), the spawn worker (`0x67316A`) and SetTransform `0x6658B0` (`0x66599B`, ~75 call
sites; no "unchanged" test). It recomputes the input and `base` from the node the entity has now
(`0x515F60`) and `r14` from `dist0` and the stored static bit. It then rewrites the slot in place
(`0x5180A0`) or moves it to the new cell keeping its state byte and rings (`0x517EC0` → insert).
Activation complete (`FUN_004F7C6A`) calls GetTransform `0x665AF0` and then SetTransform
(`0x4F815F` / `0x4F8171`) after the listeners. One of those listeners is ModelName `+0x18`
`0x6696A0`, which creates the node. So a completed activation leaves the row at
pos + R(q)·centre with `base` = cvtt(radius).

Nothing else rewrites the entry: deactivation and node destruction (`0x6693B0`), pose and box
updates (`FUN_004748B0`) and the HibernationControl state-bit writes all leave it. A row keeps its
last values until the next SetTransform. `FUN_00517710` (from `0x50C8D0`, on a hibernation-scale
change) rewrites `r14` only. Checked on the four captures:
- every placed row with a node `base` and a tinygeometry model re-quantises from the model's `INFO`
  sphere (542 / 543 / 52 / 48), including rows whose node is gone;
- all 400 low-res terrain rows (template `0x800080E4` "Lowresterrain", every one awake) re-quantise
  from their tile's `BNDS` sphere;
- a TerrainObject row keeps its registration `base` 10000 until its first activation; the re-cell
  then writes `base` 0 at the bare position (every awake tile row, and every sleeping row of a tile
  that was awake earlier).

**Grid**: 32×32 cells of 256 m from (−4096, −4096) (`FUN_005168B0`). **Quantisation**
(`FUN_00516B10`, all truncating): `dx = f32(x + 4096)`, `col = cvtt(dx) >> 8`, `cell = 32·row + col`,
`bx = cvtt(f32(f32(dx − 256·col) × 0.99609375))` (z alike); `iy = cvtt(y)`: ≥ 512 → (0xFF, 3), ≤ −512 →
(0, 0), else `v = iy + 512` → (`v & 0xFF`, `v >> 8`) (re-encoding live SceneObject positions
reproduces 74,454 of 75,095 records in the Mattias capture; the misses differ in y — entities whose
input is a render-node centre). Decode: `x = f32(cellX + bx·1.0039216)` (seen in `0x516C00`'s mask
code, `0x516CC3..0x516D3C`); `y = hi·256 + ylo − 512` is INFERRED — the job-side decode was not
located. Input position: SceneObject position + R(q)·(render node `+0x84`) when the entity has a
render node (`0x515FD2..0x51600D`), else the SceneObject position. q is the SceneObject's i16
quaternion (the Transform reader stores cvtt(q·32000), `0x63D7F0..0x63D837`). `0x434F80` scales it by
`0x3803126F` and `0x435030` normalises it. `0x824D90` then runs D3DXQuaternionNormalize,
D3DXMatrixRotationQuaternion and the row-vector `TransformNormal` (`(y·M1 + x·M0) + z·M2`). Last, an f32
add. The nine tinygeometry rows of the clean-load and
Mattias captures re-quantise exactly from the shipped `INFO` box this way, and none from the
SceneObject position alone.

## 3. Viewers

`FUN_0050C830`, up to 4: each local player's camera owner's **target entity** position
(`FUN_0050CAE0`; the character on foot, the vehicle when riding); `active[v]` and the previous frame's
copy (`FUN_00516020`, once per frame). A viewer is "local" when its player slot is joined and not
remote; only local viewers raise the ring tier.

## 4. The job (`FUN_00735640`, every frame, every block)

Submitted from `FUN_004C9740` (`0x4C9778`) in chunks of 5 blocks per job over every allocated block.
Per slot with `R = (r14 & 0x3FFF)·k`:
- prefilter: `t = cvttsd2si(cellDist − 7)` where `cellDist` = the minimum Chebyshev (max of X and Z
  gaps) distance from the cell box to any current or previous-frame viewer (`FUN_00735580`); if
  `r14 < t`, the slot's state is zeroed (with an event if it was non-zero) and the viewer test is
  skipped;
- per viewer `v`: `d² = XZ distance²`; mask bit `v` when `d² < (R+7)²` and (`d² < R²` or the old byte's
  ring nibble is non-zero) — wake inside `R`, sleep beyond `R + 7`;
- ring nibble (local viewers): 3-D distance against `t_k = base + d_k` with 7 m bands → 0x10..0x40;
- on change: push `{key, old, new}` to the event list (`0xDD5770`) and store `new`.

## 5. Event consumers

- `FUN_004F8460` (mask nibble only): mask → 0 deactivates now (`FUN_004F6AB0`); mask 0 → non-zero
  collects the entity (skipped if SceneObject `+0x1A` bit3 is set; an entity with no record in the
  component-signature registry `0xDF6D08` is not handled at all), sorted by `dist0` (its own
  HibernationControl `Distance` via `FUN_005857E0`, else 100.0) and issued **largest first** with
  `FUN_004F8DA0(e, deferred=1, 0, 1)`.
- `FUN_0050C530` (→ `0x3220000`, ring nibble): the only function that maps the tier to a streaming
  level — the entity's model streaming level on `RuntimeAssetRef` (`0x17BEED8`) becomes `4 − tier`
  (tier 0x40 → level 0 = full detail; 0 → remove); the resource manager streams model / terrainmesh
  parts 3 down to that level. Its records also come from the link-add listener (§6), which copies a
  root's ring byte onto a newly attached child (`FUN_00517080` reads both, `0x51835C` compares,
  `0x5170C0` enqueues `{child, child's byte, root's byte}`).
- Two network-replication consumers read the mask.

## 6. Activation

`FUN_004F8DA0(e, A1 deferred, A2, A3 allowed-to-complete)` (entity in EAX), in order:
1. Clear the cancel latch `0xED3B18`.
2. Begin (`0x4F7210`): a no-op unless the SceneObject state is 0. It calls every component listener's
   `+0xC`, recursing into link children; a listener whose asset is missing writes `e` to the latch.
3. Latch == `e`: deactivate, return 0, enqueue nothing (`0x4F8DBB`, `0x4F8E12`).
4. A1 ≠ 0: enqueue, return 0.
5. Otherwise, if CanActivate (`0x4F7710`, every polling listener's `+0x10`, e.g. ModelName's model
   resident) succeeds: complete (`FUN_004F7C6A`, a no-op unless state 1; every listener's `+0x18`,
   children first), then remove from the queue and return 1. If it fails: enqueue.

Callers' (A1, A2, A3):
- grid (`0x4F85EF`): (1, 0, 1);
- SetOutfit: (0, 0, 1);
- instantiate `0x6748A0`: (bit3, 1, !bit3);
- the other triggers below: (0, 1, 1);
- the link-add path `0x5183B2` enqueues directly (A2 0, A3 1), only under a state-2 root.

**Pending container** `0xDF9C10`. A record is `{u32 serial, u8 flags}`:
- serial `[0xD6CB44]`, post-incremented;
- bit0 ready, bit1 priority (SceneObject `+0x18` bit14, cleared on enqueue), bit3 A2, bit4 A3.

A duplicate key is rewritten in place: new serial (to the back), ready bit lost. The container grows
by ×1.15 + 64 instead of dropping entries, and removal is swap-with-last.

**The pump** is the second half of `FUN_004F8460` (`0x4F85FC..0x4F8D92`). It runs every frame, right
after the event loop.
- An empty queue resets the serial and returns.
- Otherwise it walks the records in serial order with `deadline = QPC + [0xD6CB48]` µs:
  - an unready entry is polled (polls are never budgeted); the first one still unready is the
    *blocker*;
  - before the blocker, a ready entry with A3 is eligible; after it, only ready priority entries
    with A3 are;
  - an eligible entry completes and leaves the queue unless the clock has reached the deadline, in
    which case it is deferred;
  - entries without A3 are polled but never completed.
- `[0xD6CB48]` becomes +300 after a pass that deferred anything, else 1000.
- Stall breaker, once per pass: the same blocker as last pass counts up, +1 while resource class-3
  I/O is busy, else to the next multiple of 64. At 0x200 it gets a forced poll (result discarded);
  at 0x800 it is removed and deactivated. A different blocker, or none, resets the count.
- The world-ready check `0x4BA2A7` waits for an empty queue.
- A config bool `[0x1175D40]` (0 in every capture) switches the rule after the blocker to a
  `dist0` / viewer-distance test.

**Wake triggers other than the grid** (callers of `FUN_004F8DA0`):

| site | trigger |
|---|---|
| `0x538DF3` | RiderLink added: wake the rider when its seat is awake |
| `0x4FD510` | RuntimePhysicalLink added: wake the child when its parent is awake |
| `0x518389` / `0x5183B2` | link added (RPL, SeatLink, RiderLink, RuntimeEntranceLink, EquipmentLink): remove the child from the grid; begin it (`0x518389`) and enqueue it (`0x5183B2`, not already pending) when its root is awake |
| `0x5DFAB7` | `Player.SetOutfit` (deactivate, swap the model, activate) |
| `0x6748A0` | `FUN_006746D0` instantiate: only when the new entity's computed viewer mask is non-zero |
| `0x49B2A0` | template spawn (`FUN_0049AFB0`), same mask gate |
| `0x4E1A79` | population `OnUnitSpawned` — no distance gate |
| `0x4D2C96` | destruction-script command `0x7FD8E763` — no distance gate |
| `0x4B5DE2` | delayed-spawn list `0xD6B6F0` |
| `0x531B7E` | reusing a pooled projectile |

**Deactivation triggers** (`FUN_004F6AB0` removes a non-asleep entity from the pending queue first):
grid mask → 0 (`0x4F85B9`, before the pump of the same frame); activation cancel (`0x4F8E12`); stall
breaker (`0x4F8D47`); SetOutfit (`0x5DFA54`); entity destroy `FUN_004F2A90` (`0x4F2B68`); `Object.Remove`
(`0x5CDCF9` → `0x248ABD0`: sets SceneObject `+0x1A |= 8` so the grid never re-wakes it); returning a
pooled projectile (`0x472469`). Deactivation recurses into the link children and never touches the
grid entry or its mask.

**Links** (owner `+0x44` → child `+0x60`): RuntimePhysicalLink `0xDF9110`, RuntimeEntranceLink
`0xDF9210`, SeatLink `0xDF8188`, RiderLink `0xDF8408`, RuntimeEquipmentLink `0xDF9510` — waking a
vehicle wakes its seats, riders and their equipment; a child never wakes its parent. Detaching
(`0x5181E0`) re-inserts the child into the grid with mask 0 and no state check, so a detached awake
child stays awake until a viewer next comes within its radius.

**Runtime spawns** (`FUN_006746D0`): the new entity is inserted with a computed viewer mask
(`[0x1175DD4] = 1` asks `0x516C00` to compute it into `[0x1175DD0]`); if the mask is non-zero its
streaming level is set from the mask (`FUN_0050BFC0(ent, mask)`, `0x6747E4`) and it activates
(`0x6748A0`); a template whose `HibernationControl` Flags bit0 is set is removed when spawned out of
range (`0x67318F..0x6731A6`, `0x6747E9`); when the mask is 0 and `[0xCFC157]` is 0 the grid insert is
skipped. Otherwise it sleeps until the grid job wakes it (INFERRED — not observed live).
- The key is taken first (`0x6746F6`), so a failed spawn still consumes one.
- The SceneObject row (`FUN_00673070`, `0x6730C6..0x67316A`): position, the i16 quaternion
  (`Pg.Spawn` builds it from the yaw alone, in degrees), template `+0x14`, `+0x18 = 0x0FFF` (asleep, not
  in the grid until the add listener registers it), `+0x1A = (arg4 & 1) << 2` (non-static when set),
  `+0x1B = 0x40` and then bits 6–7 cleared (`0x67484C`). `arg4` = `flags` bit 0, else the template's
  `NetCategoryInfo` bit 9.
- Out of range with the template's HC Flags bit 0: the row is set to `0xFFF`, removed (`0x67319B`,
  `0x6731A6` → `0x677260`) before any link child is spawned, and the key stored back is 0 — `Pg.Spawn`
  returns nil.
- The direct activation is `FUN_004F8DA0(key, A1 = 0, A2 = 1, A3 = 1)` inside the call (begin,
  complete at once when CanActivate passes, else enqueued).
- Link children (PhysicalLink / ConstraintLink / EntranceLink / RiderLink) are spawned without a
  mask, so they are not in the grid. In all four captures, a runtime key is out of the grid exactly
  when it is a link child (mid-mission: 23,044 link children, 2,507 in the grid).
- `Pg.Spawn(template name | guid, x, y, z, yaw, arg6 = false, arg7 = true, arg8 = 0)` (`0x5D5D20`):
  `flags` = `arg7 && Net.IsEnabled ([0xDFBD74]) && the template's NetCategoryInfo low nibble != 0`
  (`0x5D5F12..0x5D5F2B`; `Net.IsEnabled` is on in single player); with that set on a client it returns
  nil without spawning (`0x5D5F31`). After a spawn: the net registration `0x6B2F70` when `flags`;
  `SceneObject +0x1A |= 2` (`0x5D5FDC`); with arg6, the entity's RtAlphaAnimation record is removed
  (`0x5E0580`, `0x5D5FE7`); with arg8, a physics collision-group copy from that entity (`0x432740` /
  `0x4336D0`, INFERRED from the Xbox body). The names `bLink` / `bHighDetail` belong to
  `MrxUtil.SpawnActor`'s arguments 6–7, not to `Pg.Spawn`'s.

**Attach listener** (`0x5182C0`, also on detach `0x5181E0`): besides removing the child from the grid
and waking it under an awake root, it syncs the child's ring byte to the root's whenever they differ —
which can also put the child to sleep or drop its stream when the root is asleep.

## 6a. What activation tells scripts and systems

Begin (`0x4F7210`), complete (`0x4F7C6A`) and deactivate (`0x4F6AB0`) walk one listener array,
`0xED3D20[0 .. [0x1175D44] = 99]` (`{vtable, name hash, signature bit}`, identical in three
captures). A listener runs only if its bit is set in the entity's component signature (`0xDF6D08`,
own else template). Slots: `+0xC` begin, `+0x10` poll, `+0x18` complete, `+0x1C` deactivate.

| idx | component | complete `+0x18` | deactivate `+0x1C` |
|---|---|---|---|
| 3 | HibernationControl | `0x66AA90`: state 2 | `0x66AAC0`: state 0 |
| 4 | ModelName | `0x6696A0`: render node, RuntimeHealth | `0x6693B0` |
| 59 / 60 / 61 | TerrainObject / LowResTerrainObject / LightObject | `0x66CAC0` / `0x66D370` / `0x66D630` | |
| 71 / 73 | PopulationSimpleSpawner / DangerousBuilding | begin `0x66B5C0` queues the owner (pending list `0x16D6970`, cap 900) | `0x66B5D0` → `0x4E5630` |
| 89 | ObjectScript | `0x66C2D0`: `OnActivate(guid, RuntimeOwnerGuid or nil, (float)iArg)` | `0x66C350`: `OnDeactivate`, same arguments |

**Complete:**
- Link children run first: RPL, RuntimeEntranceLink, SeatLink, RiderLink, EquipmentLink.
- Then the listeners, in index order.
- Then the SetTransform re-cell, then RuntimeSceneObject `+0x20 |= 4`.
- So inside `OnActivate` `Object.IsAwake` is already true, the model and health exist, and the row is
  not yet re-celled.

**Deactivate:**
- Runs only from a non-zero state: the entity leaves the pending queue, then the listeners run (state 0
  before `OnDeactivate`).
- Then the 21 Runtime* containers of `0xEDBAC8`, then link children, parent first.

**ObjectScript.** Record `{u32 script hash, i32 iArg}` (container `0x17BDD58`); the `schm` names the
fields `ScriptName` (Hash) and `Param` (Int) — 327 placed records in the retail archive over five
scripts (`dangerousbuilding` ×295, `factionzone`, `goal`, `spyhunter`, `pmcgate`; 12 records name no
script), and 241 worldentity template groups carry one too. No runtime key has an ObjectScript record.
- Begin requests the script resource (type `0x42498680`); a missing one cancels the activation.
- The poll waits for module state 5, so `Init` (run at state 4) precedes the first `OnActivate`.
- `OnActivate` is a synchronous `lua_pcall`, skipped when the function is undefined.
- The call is `OnActivate(guid, RuntimeOwnerGuid or nil, (float)iArg, env)` (`0x5A0F10` → `0x6C6F00` →
  `0x5A0CC0`): the module's env is a hidden fourth argument; `OnDeactivate` gets the same four. The
  name is looked up through the env's index chain (its bases, then `_G`). An error's message is popped
  and dropped: nothing is logged, nothing is fatal.
- The script module (see `object_script_modules.md`) is one resource per script: every entity using
  it shares one env. Activation begin AddRefs it, deactivate releases it; at count 0 `Deinit(env)` runs
  and the module drops to state 3, so the next AddRef runs `Init(env)` again without re-running the
  body.

**Lua bindings and events:**
- `Object.IsAwake` (`0x5CF300`) = state == 2. `Object.IsHibernated` (`0x5CF240`) = state != 2. Both
  push nil for a guid with no SceneObject row. Neither reads the grid.
- `Event.ObjectHibernation` is not raised by a transition. It is a condition node (factory
  `0x5F2530`, 0x30 bytes, bucket 7; vtable `0xBBB448` = {parse `0x5F2300`, release, poll `0x5F2440`, …})
  that the script update (`FUN_005EB560`, after the grid pump in `FUN_004C9740`) polls each frame. On
  a true poll the callback runs; a one-shot node is then released, a persistent one fires on every
  true poll.
- Parse (`0x5F2300`), reading the params table in order with an index that moves only past what it
  reads:
  - a string or number first is a layer name, hashed into `+0x20`;
  - then a guid, only from a lightuserdata or userdata (`0x59FF50`), into `+0x24`;
  - then the phase string; absent, it is `"a"` (`0xBB23F0`). First letter, case-folded, `== 'a'` sets
    `+0x28 = 2`; anything else sets `+0x28 = 0` and forces `+0x2C = -1`;
  - then an optional number, truncated (`cvttss2si`), into `+0x2C` (else -1): a model detail level.
  - Neither a guid nor a layer name: the parse fails, the node is freed and `Event.Create` returns nil.
- The entity test (`0x5F2280` → relocated `0x0246F220`): false without a SceneObject row; false unless
  the state equals `+0x28` exactly (a waking entity, state 1, passes neither form); true when `+0x2C` is
  -1; true when the entity has no ModelName (own, else template); otherwise its model resource must be
  loaded (status 2 or 4) and, while the streaming manager is busy (`[0x1176630]+0x4C35C`, INFERRED), at
  detail ≥ `+0x2C`. No shipped registration passes a detail.
- The guid form tests the guid; with no guid, the layer form is true when the layer's status is 3, or,
  at status 2 or 4, when every RuntimeLayerId row of the layer passes the entity test.

**Population:** a spawner owner enters the pending list at activation begin. Its readiness is 2 only at
state 2 with its Path and model resources resident (`0x2467040`).

## 7. HibernationControl

Schema v83, 6 bytes: `+0 u16 Distance`, `+2 u8 Q2Distance`, `+3 u8 Q1Distance`, `+4 u8 Q0Distance`,
`+5` bits `Flags` (bit0, read when spawning from a template) and `NoDelOnHibernateIfPreplaced`.
Placed blocks carry `{u32 key, 6-byte payload}` records; templates carry the rest.
