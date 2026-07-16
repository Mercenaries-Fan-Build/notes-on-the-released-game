# Saboteur ↔ Mercs2 cross-validation — vehicle drive & save/serialize

Companion to [`saboteur_damage_solver_symbol_map.md`](saboteur_damage_solver_symbol_map.md). Uses the
named WildStar (Saboteur Xbox360 devkit) map as the reference to attack two partially-/un-reversed
Mercs2 subsystems. Same honesty boundary: WildStar is a **sibling fork** (see
[`saboteur_engine_comparison.md`](../saboteur_engine_comparison.md)) — algorithm/format *shape* is the
reference, not byte-identical to Mercs2.

Reference decompiles: `output/_ghidra_saboteur/wildstar_vehicle_save_decomp.txt`
(Ghidra `PowerPC:BE:64:A2ALT-32addr`, names from `WildStar_d.map`).

## Save / serialize — vs the Mercs2 `ProfileHash`/`saveProfile` wall
`WSSaveLoadManager` (all named): `SaveGame` 0x8265f070, `LoadGame` 0x8265f9f8, `LoadCheckpoint`
0x826603d0, `SaveLuaFloat` 0x826609e8, `LoadLuaFloat` 0x826611f8, `LoadLuaString` 0x82661368,
`ExecutePendingSaveLoad` 0x8265ea98.

**Recovered format (WildStar):**
- `SaveGame` opens a `PblMemFile` read/write, buffer size `0x19000` (~100 KB).
- Header magic written first: **`PblFile::Write32(0x53563030)` = ASCII `"SV00"`**, then a `Write32(0)`
  version/size placeholder, then the serialized body.
- Body = a **flat stream of typed Lua values**: `SaveLuaFloat`→`PblFile::WriteFloat`,
  strings via `WriteString`/`ReadString` (capped 0x80 = 128 B). Symmetric `Load*` readers.

**Cross-validation to Mercs2:** Mercs2 save = 13404-B LE header + zlib@0x468 carrying a
`return{}` Lua-source blob ([[rows-26-29-weapons-save-code-maps]]). Same *pattern* (magic + version +
typed value stream) but Mercs2 wraps it in zlib and adds `ProfileHash`. WildStar's serializer gives
the primitive shape; the Mercs2 `ProfileHash` constant/algorithm still needs the Mercs2 body (BSim
match on the prototype). **No checksum seen in the `SaveGame` prologue** — if WildStar hashes, it's
later in the (truncated) body; re-pull the full function to confirm.

## Vehicle drive model — vs Mercs2's custom-raycast solver
Named: `WSCar::Update` 0x825c86e8, `WSCar::SteerAssist` 0x825c8dd0, `WSCar::AutoDrive` 0x825c8de0,
`WSCar::CreatePhysicsVehicle` 0x825c8c50, `WSTank::Update` 0x825c9c18, `WSTank::AutoDrive` 0x825ca228,
`WSVehicle::Update` 0x825d6df0, `WSVehicle::GetSteeringValue` 0x825d5e58.

- `WSCar::SteerAssist` = **stubbed `return 0`** in this debug build (assist path compiled out).
- `WSVehicle::Update` = the full per-frame drive tick (large; captured for teardown).
- **Divergence signal:** WildStar has `CreatePhysicsVehicle`/`GetPhysicsVehicle` → looks like the
  **Havok vehicle kit**, whereas Mercs2's drive model is a **custom raycast solver** (memory
  [[vehicle-road-ai-pc-code-maps]]). So this is a *contrast* cross-check (how each fork drove the same
  design), not a copy — still useful for naming Mercs2's tick structure.

## Status
Vehicle+save reference side = **done** (this doc). Mercs2-side bodies pending the **BSim** match
(WildStar full-analysis in progress in `analysis/wildstar_ghidra` / `WildStarXenon`).
