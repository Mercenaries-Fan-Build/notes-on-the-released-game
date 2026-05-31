# Glue Gap Closeout Plan

**Date:** 2026-05-30  
**Scope:** Integration gaps between extracted game data, Python pipeline, Rust validation, and UE5 recreation.

This document lists remaining glue work with digging type, effort, dependencies, and acceptance criteria. Rust validation items wired in `tools/wad_simulator/` are marked **partial** where consumption exists but gameplay/export glue is still open.

---

## 1. SKIN → `anim_gltf_export` (replace rigid bind-0)

| Field | Detail |
|-------|--------|
| **Digging type** | Python tool + format doc (weights verified in `ucfx_mesh_codec.py`; SKIN marker structure validated in Rust) |
| **Effort** | 2–4 days |
| **Dependencies** | Skinned mesh samples with HIER+SKIN+STRM; working skeletal GLB path (`export_skinned_mesh.py`); Havok bind pose from animation blocks |
| **Acceptance criteria** | At least one retail skinned PMC/world mesh exports to GLB with ≥2 bone influences per weighted vertex; UE5 import shows correct deformation (not all vertices bound to bone 0); JSON sidecar lists bone indices/weights matching STRM DECL offsets (+16/+20 for standard layout) |

**Status:** Rust SKIN container check in `wad_simulator` / `ucfx_byteswap`; export still uses rigid bind-0 in `anim_gltf_export.py`.

---

## 2. Water sea level → `setup_water.py` from `watr`

| Field | Detail |
|-------|--------|
| **Digging type** | Python tool (`watermap_decode.py`) + UE Editor manual tuning |
| **Effort** | 1–2 days |
| **Dependencies** | `output/watermap_decode.json` or PNG rasters; documented -36 m wet plateau vs `SEA_LEVEL_UE=-2500`; coordinate `game_to_ue` |
| **Acceptance criteria** | `setup_water.py` reads decoded height/mask (or a generated UE data asset); ocean plane Z matches open-water `-36` m game height within agreed tolerance; Maracaibo coastline visually aligns with static mesh shoreline in-editor |

**Status:** Rust validates `watr` 495 669 B / 257² grid; no UE wiring yet.

---

## 3. Full `extract-placements` on powerful machine

| Field | Detail |
|-------|--------|
| **Digging type** | Python pipeline (`make extract-placements`) — no RE |
| **Effort** | 0.5–1 day wall-clock (machine time) |
| **Dependencies** | Full `vz.wad` extract in `output/`; disk for `layers_static.json`, `all_vz_state.json`, ECS merge outputs |
| **Acceptance criteria** | `output/placements/layers_static.json` has ~62k records; vz_state overlay JSON present; `populate_world.py` runs without missing placement source errors |

---

## 4. Blueprint / C++ spawn manager + combat

| Field | Detail |
|-------|--------|
| **Digging type** | RE (x32dbg/Ghidra on `Merc2.exe`) + UE gameplay implementation |
| **Effort** | 2–4 weeks |
| **Dependencies** | Mission/spawn data from SCRB/Lua harvest; world_entity placements; optional Ghidra annotations |
| **Acceptance criteria** | Demo map spawns at least one mission-tagged entity set from verified data; combat damage pipeline stubbed or linked to existing character blueprint |

---

## 5. Soundbank event names (hash only)

| Field | Detail |
|-------|--------|
| **Digging type** | RE + rainbow table / string harvest |
| **Effort** | 3–5 days |
| **Dependencies** | `soundbank` UCFX decode; FaceFX/string tables if names indirect; Rust wavebank/IMA validation (done) |
| **Acceptance criteria** | `dlc_audio_manifest.json` or successor maps clip/event hashes to human-readable names for ≥90% of Maracaibo combat/UI samples used in demo |

---

## 6. SCRB → UE materials

| Field | Detail |
|-------|--------|
| **Digging type** | Python (`material_probe.py`) + format doc + UE Editor material graph |
| **Effort** | 1–2 weeks |
| **Dependencies** | SCRB chunk layouts (`shader_scrb` type); texture hash resolution; MTRL/PRMT validation patterns (Rust material consumer is structural only) |
| **Acceptance criteria** | One retail SCRB maps to a UE5 Material Instance with matching albedo/normal where textures exist; in-engine shader matches reference screenshot on a test mesh |

---

## 7. `anim_gltf_export` track order vs HIER indices

| Field | Detail |
|-------|--------|
| **Digging type** | Python + RE (Havok hierarchy vs glTF joint order) |
| **Effort** | 2–3 days |
| **Dependencies** | `hk_anim` decompression; HIER 176-byte nodes; sample animation with known bone motion |
| **Acceptance criteria** | Exported GLB animation rotates correct limb (e.g. shoulder vs foot) when played in viewer and UE5; joint index table documented in `docs/skeleton_status.md` |

---

## 8. Mission spawn manager runtime

| Field | Detail |
|-------|--------|
| **Digging type** | RE (Mercs 1 `RsMissionDataManager` lineage) + UE Blueprint/C++ |
| **Effort** | 1–2 weeks |
| **Dependencies** | Item 4; mission_flow / vz_state visibility rules; Lua chunk harvest under `output/placements/` |
| **Acceptance criteria** | Act/mission toggle hides/shows a verified vz_state overlay set in UE5 Data Layers or equivalent; behavior matches documented pristine vs ruined counts for one Maracaibo district |

---

## Optional / lower priority

| Item | Digging | Effort | Notes |
|------|---------|--------|-------|
| Road graph / destruction blocks | RE + Python probe | 3–5 days | Rust hook: extend `consume_structural` when `path` / destruction type_hash layouts are documented |
| fxdict → Niagara | Python + UE manual | 1 week | DICT stride validated in Rust; parameter semantics still hypothesis |
| World entity ECS full spawn | Python placements + UE | 3–5 days | `TYPE_ID_WORLD_ENTITY_DATA` uses structural consumer until ECS component map is complete |

---

## 9. UE binding manifest pipeline

| Field | Detail |
|-------|--------|
| **Digging type** | Python manifest builder + UE Editor applicator (no RE) |
| **Effort** | 1–2 days (initial); roads/destruction visual pass included |
| **Dependencies** | `make extract-placements`; optional `road-graph`, `destruction-graph`, `watermap-decode`, `build-c3-cell-manifest` |
| **Acceptance criteria** | `make ue-bind-manifest` writes `ue_game_binding.json` + report; `apply_world_bindings.py` applies visibility preset, water sea level, lights, hibernation; `setup_all` step 9b runs unless `MERCS2_SETUP_SKIP_BINDINGS=1`; populate falls back to legacy rules when manifest absent |

**Docs:** [`docs/ue_game_bindings.md`](ue_game_bindings.md)

---

## Recently closed (this session)

- **DEPS** byte-swap + post-swap size validation (`ucfx_byteswap`, `mercs2_formats::chunk_validate`)
- **watr** payload size formula (495 669 B retail)
- **fxdict** INFO+DICT stride (20 B × count)
- **SKIN** container structure check (marker + INFO + PRMG)
- **material_params** MTRL/PRMT structural checks
- **TYPE_HASH_WATERMAP** / `type_name_from_hash("watermap")`
- `tools/wad_simulator/README.md` validation matrix

---

## Suggested order

1. Water sea level (2) — unblocks visible world correctness  
2. Full placements (3) — unblocks populate_world at scale  
3. SKIN → glTF (1) + track order (7) — unblocks characters  
4. SCRB materials (6) — visual fidelity  
5. Audio names (5) — polish  
6. Spawn/combat/mission runtime (4, 8) — gameplay loop  
