# Runtime layer load / unload (PC v1.0)

How retail turns `Pg.LoadLayer` / `Pg.UnloadLayer` / `Pg.ReloadLayer` into placed entities and back.
Decoded 2026-10-22 from the pc-v10 code (relocated SecuROM bodies read from the `updated-chris-exports`
captures) and, where the PC body is VM-virtualised, the Xbox retail twin. Grades: PROVEN unless
marked.

## 1. The layer record

A layer is an ordinary resource of type `m2("layer")` = `0xE6B81A54` (ASET type id 9), named by
`pandemic_hash_m2(lowercase name)`. Lookup is `FUN_00874150` (through `FUN_0045E440` / `0x45E3F0`).
The record is 0x30 bytes (vtable `0xBAA860`, constructor `FUN_0068C1B0`):

| offset | meaning |
|---|---|
| `+4` / `+8` | name hash / type |
| `+0x0C..+0x13` | four u16 reference counts |
| `+0x14` | u16 status: 0 unloaded, 2 loaded (end of `OnLoad`, `0x45E659`), 3 failed (`0x87413E`), 4 written by get-or-create `FUN_00873140` and read like 2 (meaning UNPROVEN), 1 no writer found |
| `+0x18` | bit0 dynamic (`Pg.LoadLayer(name, true)`), bit1 reload in flight, bit2 static (`Pg.IsStaticLayer`), bit3 dirty: an entity of the layer was destroyed (`0x5235C1`) |

`layers_static` (block 29) is not a layer. It holds 173 type-9 layer assets, one container each. The
level script's `_tStaticLayers` (`vz/xQ!L.lua`) names 170 static layers: 169 of these 173, plus
`vz_mar_roads`, which lives in block 5. The other 4 in block 29 are never requested. `vz_base`
(block 79) is requested by `LevelBootstrap.LoadLevel` through
`Sys.RequiredAsset(LevelName .. "_base", "layer", -2, false)` (`resident/levelbootstrap.lua:14`), not
through `Pg.LoadLayer`; the teardown removes it with the static list (`xQ!L.lua:618-620`).

## 2. `Pg.LoadLayer(name, bDynamic, …)`

**In the call:**
- The request enters the Lua request tracker (`[0x1175F30]`, slots at `+0xC2C`, stride 0x28,
  count `+0xC28`; `FUN_005A2558`). Mode 0 calls `FUN_00873F20(key, 3)`: create the record or add a
  reference.
- The tracker grows by a slot when full (`0x5A288B`). `Pg.LoadLayer` then sets `+0x18 |= 1`
  (dynamic) or `|= 4` (static).

**When the layer's data arrives** (`OnLoad`, vtable slot 4, `0x45E5F0`):
- `FUN_00654940(reader, layer hash if dynamic else 0)` instantiates the container. Every COMP is
  written into its container (SceneObject, Name, HibernationControl, …); the SceneObject listener
  registers each entity in the hibernation grid.
- Then it clears bits 1 and 3 and sets status 2.
- A post-pass walks the Transform keys:
  - a SceneObject row with a template (`+0x14`) → `FUN_00673070`;
  - no template and no HibernationControl → `thunk_024ECAB0` (role UNPROVEN);
  - TinyGeometryObject rows → `FUN_004F2A90`.

**RuntimeLayerId** (`0x017BF478`) is written in `FUN_00654940` (`0x654E58..0x654EAB`):
- Only for a dynamic layer, for every key of the container's Transform COMP, value = the layer hash.
- 13,238 rows in the mid-mission capture: all dynamic layers, none of block 29 or `vz_base`, no
  spawned keys.
- A set-or-overwrite (`FUN_0064A600`), so a key two dynamic layers place belongs to the last one
  loaded.
- Not cleared on deactivate.

**Completion:** `FUN_005A28F0`, from the script update (`FUN_005A1890` → `FUN_005A2BC0`; per frame
INFERRED), polls the slots. A load completes when the status is 2, 3 or 4, with
`bSuccess = status != 3`. It calls the request's callback (the Lua sees `_LayerStatusChange("Load",
name, "layer", bSuccess)`, `mrxlayermanager.lua:200-224`). So the entities exist at least one poll
before the callback. The bindings' argument order is `Pg.LoadLayer(sName, bDynamic, fCallback,
tCallbackData, bLoadingScreen)` and `Pg.ReloadLayer`/`UnloadLayer(sName, fCallback, tCallbackData,
bLoadingScreen)` (`mrxlayermanager.lua:224-236`); the callback data `{"Load"}` / `{"Reload"}` /
`{"Unload"}` is what arrives as `sRequestType`, so the callback receives the data unpacked, then
`(sLayerName, "layer", bSuccess)` (INFERRED from the handler's signature, `:245`).

## 3. `Pg.UnloadLayer` / `Pg.ReloadLayer`

**`UnloadLayer`:**
- Guard: unless `[0x1175F58]` (`Pg.UnloadingStaticLayers`) or the layer's dynamic bit is set, it
  returns nil silently (`0x5D4F37`). The level teardown sets the flag then removes the static list
  and `vz_base` (`xQ!L.lua:619-620`).
- Mode 1 releases a reference (`FUN_00873F80`). The request completes when the record is gone or its
  counts are 0, `bSuccess` true only then; a layer another holder still references completes with
  false.
- Layer `Unload` (vtable slot 11, PC VM `0x45E4E0` → `0x24EE490`; Xbox `FUN_821AE540`): for a
  dynamic layer (or global `+0x62`), every RuntimeLayerId row of the layer hash is destroyed
  (`FUN_82255FF0`), unless exempt (`FUN_82437CF8`: the player-controlled entity and what is linked to
  it). Then status 0.
  - Destroy runs the destroy listeners and the deactivate step, then queues a deferred delete.
  - Awake or asleep makes no difference.
  - Names and grid rows go when the delete is reaped, through the container listeners (INFERRED).

**`ReloadLayer`** (dynamic layers only):
- A missing or unreferenced record becomes a load (`0x5A2590..0x5A25B4`).
- Otherwise the layer is re-read (`FUN_008741A0`; whether the old entities are destroyed first is
  UNPROVEN), unless `[0xCFE0F2]` and not dirty, in which case it succeeds at once.
- Completion waits for status 2/4 with bit1 clear.

## 4. Readers

- `Event.ObjectHibernation`'s layer form (`0x5F2440`): status 3 → true; status 2 or 4 → every
  RuntimeLayerId row of the layer must pass the entity test; else false. A static layer has no rows
  and passes at status 2.
- The destroy dirty mark (`0x5235A8`) and the layer `Unload`.
