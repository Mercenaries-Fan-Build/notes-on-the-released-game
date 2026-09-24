# Mercenaries 2 — reverse engineering & recreation

Tooling, research notes, and a from-scratch engine for **Mercenaries 2: World in Flames** (Pandemic
Studios, 2008, PC). This repo is for **people who already own the PC game** and are comfortable with
Rust, shells, and long jobs. The docs describe **what the tools expect and what they emit** — they are
not a promise of "works on every machine."

> This repo ships **no** Mercenaries 2 game data. Bring your own legal copy of the game.

## What's here

The project is several efforts sharing one knowledge corpus and one asset-format layer:

- **Reverse engineering** — a ~27k-function named Ghidra decompilation of the unpacked PC exe, a live
  x32dbg oracle bridge, and per-subsystem code maps. The shipped 32-bit exe is the specification and
  oracle. (SecuROM is fully solved — decrypted, decompiled, and removable.)
- **A 64-bit Rust/`wgpu` engine reimplementation** — the north star: a ~40-crate workspace
  (`tools/wad_simulator/`) that loads the **original game's assets** and reimplements the engine one
  gated system at a time. ~26 of 32 subsystems now have real implementations.
- **The unofficial fix-pack** — fixes for the rushed PC port, shipped as layered `-patch.wad` overlays
  on the retail engine.
- **Asset injection / modding / DLC port** — novel models, skins, and Xbox/PS3 DLC brought to the PC
  game **additively**, via a `vz-patch.wad` overlay.
- **Online restore** — a FESL/Theater emulator + TLS shim that revives the dead EA online services.
- **The legacy extraction pipeline** — Python tools + a three.js viewer that decode WAD assets to
  standard formats (glTF/PNG). Still used for bulk extraction; the Rust workspace is the active path.

**Working on this repo (human or AI agent)? Read [AGENTS.md](AGENTS.md) first** — it carries the
standing mandates, the repo topology, and the corpus-first workflow.

## Repository layout

| Path | What |
|------|------|
| `tools/wad_simulator/` | **The Rust engine workspace** (a nested git repo). ~40 crates: the engine, format parsers, RE probes, and mod tooling. See its `Cargo.toml`. |
| `tools/corpus_mcp/` | The corpus MCP server — a LanceDB index over docs, memory, decomp, commits, and past sessions. |
| `tools/ghidra_12.1_PUBLIC/` + `tools/jdk21/` | Bundled Ghidra + JDK for reverse engineering (portable, no install). |
| `tools/*.py`, `scripts/*.sh`, `Makefile` | The legacy extraction/conversion pipeline (`make help`). |
| `docs/` | Format specs, RE code maps, the modernization charter + scoreboard, the fix-pack and modding guides. |
| `game-scripts/` | UE5 Editor Python from the original recreation effort (reference). |
| `viewer/` | Three.js asset viewer (Vite + npm). |
| `coopserver/`, `tlsterm/`, `webapp/` | Online-restore services + a corpus web app. |
| `mods/` | Runtime tracing ASI modules (behavioral oracles). |

## Quick start — the Rust workspace

```bash
cd tools/wad_simulator
cargo build --release          # binaries land in target/release/
```

- **`qm`** — the mod packager. `qm lint ./my-shipment` is hermetic (no game, no network — CI-safe);
  `qm build` / `qm link` need the retail WADs. Start from the
  [Shipment template](https://github.com/Mercenaries-Fan-Build/mercs2-shipment-template).
- **`wad_simulator`** — engine-accurate WAD consumption simulator (validates conversions, catches
  corruption before runtime).
- **`loadprobe`** — scores `pmc_blackbox.log` to quantify world-load progress and classify the
  end-state (crashed / hung / loaded).
- **`ucfx_byteswap`** — Xbox 360 (big-endian) → PC (little-endian) UCFX converter.
- **`mercs2_game`** — the reimplemented engine. Default boot = full-world load; `--stream` = streaming
  dev boot.

Many tests need a real `vz.wad`; without one they **skip silently and pass**. Point the workspace at
your install first — `bash scripts/find-vz-wad.sh --write` (writes the gitignored `.mercs2-local.toml`)
or set `MERCS2_GAME_DIR` / `VZ_WAD`.

## Quick start — legacy extraction pipeline

From a retail PC install (bring your own). The pipeline slices FFCS `.wad` archives, decompresses
`sges` blocks, and converts meshes/textures/placements to standard formats.

```bash
make extract-all ZIP="/path/to/Mercenaries 2 World in Flames.zip" OUTPUT=./output
```

The script assumes a normal PC archive whose important part is **`data/*.wad`** (`shell.wad`, `vz.wad`,
`English.wad`, …). It aborts with a clear error if `output/data/*.wad` is missing after unzip. Full run
processes **every** pack including the very large `vz`; use `--quick` / `--vz-max` / `--no-decompress`
for a slice. See `make help` and [`tools/README.md`](tools/README.md) for the target list.

Probing a **single** WAD block? Use `tools/extract_single_block.py` (extract → decompress → optional
decode → clean up), not a bulk decompress.

## Three.js viewer

```bash
cd viewer && npm install && npm run dev
```

The sidebar loads `mesh.obj` / `mesh.gltf` from discovered `review/` folders under the repo. Static
`vite build` output omits the discovery API — use `npm run dev` or `vite preview`.

## Docs

- [AGENTS.md](AGENTS.md) — the operational guide: mandates, topology, programs, workflow.
- [docs/format_reference.md](docs/format_reference.md) — FFCS / sges / UCFX / textures / Havok layouts.
- [docs/aset_format.md](docs/aset_format.md) — ASET decode.
- [docs/modernization/00_charter.md](docs/modernization/00_charter.md) — the engine-reimpl charter, and
  [engine_support_inventory.md](docs/modernization/engine_support_inventory.md) — the 32-row scoreboard.
- [docs/modding/field_guide.md](docs/modding/field_guide.md) + [docs/asset_injection_playbook.md](docs/asset_injection_playbook.md) — modding.
- [docs/fixpack/bug_register.md](docs/fixpack/bug_register.md) — the fix-pack backlog.
- [tools/README.md](tools/README.md) — the Python CLIs.

## License

Original **source code and documentation** in this repository are under the **MIT License** — see
[LICENSE](LICENSE). Third-party libraries and Unreal-related terms are summarized in [NOTICE](NOTICE).
This repo does **not** ship Mercenaries 2 game data; bring your own legal copy of the game.
