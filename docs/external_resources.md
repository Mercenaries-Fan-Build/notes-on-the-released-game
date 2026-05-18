# External tools & community references (Mercenaries 2 / FFCS / Lua)

**Date:** 2026-05-15  
**Status:** Curated pointers for standing on prior work — verify versions locally before relying on disassembly output.

## FFCS / archives

| Resource | URL | Notes |
|----------|-----|--------|
| QuickBMS | https://aluigi.altervista.org/quickbms.htm | Compression / `comtype_scan2` workflows; see [docs/quickbms_notes.md](quickbms_notes.md). |
| GameExtractor | https://github.com/wattostudios/GameExtractor | Lists Mercs2 via **Archive_BLOCK**; see [docs/game_extractor_notes.md](game_extractor_notes.md). |

## Lua bytecode (LuaQ)

| Resource | URL | Notes |
|----------|-----|--------|
| LuaDisAss (jcmnn) | https://github.com/jcmnn/LuaDisAss | Disassembler the plan targets for `scripts_vz` LuaQ chunks; Lua 5.0/5.1-era tooling — confirm Mercs2 bytecode version from headers before trusting control-flow recovery. |
| Unluac / luadec (ecosystem) | search “unluac github” / “luadec” | Alternative paths if LuaDisAss mismatches Mercs2’s exact Lua build; always diff against known string tables from blobs. |

## Forums / RE hubs (search-first)

- **ZenHAX** — binary formats, archive reverse engineering threads.  
- **XeNTaX / Zenhax mirror** — game extraction and container discussions.  
- **ResHax** — research-oriented RE community (search Mercenaries / Pandemic / FFCS).

These sites move; prefer capturing **direct repo links** and **archive.org** snapshots in PRs when a thread is cited as evidence for a field layout.

## This repo’s parsers (source of truth for our pipeline)

- `tools/ffcs_wad.py` — FFCS chunk table + `PTHS` path dump.  
- `tools/placement_extractor.py` — `layers_static` / `vz_state` placement records.  
- `tools/ucfx_ecs_codec.py` — ECS `COMP` harvest (ModelName, HibernationControl, regions, …).  
- `tools/aset_decoder.py` — `ASET` row decode → `output/block_dependency_graph.json`.

When upstream tooling disagrees with our byte-level docs, **trust verified hex in `docs/`** and file a minimal repro for upstream.

## Modding deep-dive

- [`docs/modding_deep_dive.md`](modding_deep_dive.md) — comprehensive analysis of DRM (SecuROM), `vz.bin`, three hash layers, Lua bytecode format, CSUM trailers, and a phased modding roadmap.
