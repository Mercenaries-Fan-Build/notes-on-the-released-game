# loadprobe

**World-load progress + forensic analyzer for `pmc_blackbox.log` (Mercenaries 2 PC)**

loadprobe scores how far a Mercenaries 2 world-load got against the milestone ladder, classifies the end-state (REACHED-WORLD / CRASH@EIP / HANG / TRUNCATED), and surfaces every non-routine diagnostic line + high-signal Lua markers for rapid failure triage.

## Features

- **Milestone tracking**: Traces load progress through 21 phases (process init → GlobalExit)
- **End-state classification**: Distinguishes crashes, hangs, truncations, and full boots
- **Crash diagnostics**: Maps crash EIPs to subsystems with known-bugs database
- **Texture-pool health**: Analyzes component-cache capacity, garbage, and refills
- **Performance gaps**: Reports the top N inter-line time gaps to spot stalls
- **Self-attribution**: Binds metrics to exact game bytes via SHA-256 fingerprints
- **JSON output**: Machine-readable reports for automation + scripting
- **ANSI colors**: Human-readable text dump with progress bars and icons

## Installation

From the Rust project root:

```bash
cargo install --path tools/wad_simulator/crates/loadprobe
```

Or build locally:

```bash
cd tools/wad_simulator/crates/loadprobe
cargo build --release
./target/release/loadprobe --help
```

## Usage

### Analyze a log file

```bash
loadprobe /path/to/pmc_blackbox.log
```

Example output excerpt:
```
────────────────────────────────────────────────────────────────────────────────
loadprobe /path/to/pmc_blackbox.log
────────────────────────────────────────────────────────────────────────────────
LOADED  100%  ████████████████████████████░░  (phase 20/20: World fully loaded (GlobalExit))
VERDICT: REACHED-WORLD booted into game — GlobalExit complete, load finished
Span: 21:02:43.033 → 21:05:52.184  (3m9s)  •  4821 records
Last progress: [21:05:52.184] GlobalExit - Complete

── BUILD / RUN IDENTITY ───────────────────────
  log   (this log)            sha256 a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2
...
```

### Output as JSON

```bash
loadprobe /path/to/pmc_blackbox.log --json
```

Returns structured JSON with all phases, crashes, pool health, and artifacts.

### Suppress routine sources

By default, `[lua]` and `[pool]` messages are excluded from the line dump. Customize:

```bash
loadprobe /path/to/pmc_blackbox.log --routine lua,pool,blackbox
```

### Show high-signal Lua markers only

```bash
loadprobe /path/to/pmc_blackbox.log --signals "###!,###,!!!,##@,@@@,***,=-="
```

### Print the milestone ladder

```bash
loadprobe --milestones
```

### Disable ANSI colors

```bash
loadprobe /path/to/pmc_blackbox.log --no-color
```

## Exit Codes

- **0**: `REACHED-WORLD` — booted into the game (load complete)
- **10**: `CRASH` — hit a crash EIP before completing the load
- **11**: `HANG` — load wedged with no progress for N seconds
- **12**: `TRUNCATED` — log ended without a complete load (no clear crash/hang)

Scripts can branch on these codes:

```bash
loadprobe game.log
case $? in
  0) echo "Load successful" ;;
  10) echo "Pre-load crash" ;;
  11) echo "Load hang" ;;
  12) echo "Truncated (user closed?)" ;;
esac
```

## Configuration

| Flag | Default | Description |
|------|---------|-------------|
| `--routine` | `lua,pool` | Comma-separated sources to suppress from line dump |
| `--hang-secs` | `10` | Steady-pool duration (seconds) to classify a HANG |
| `--top-gaps` | `5` | Number of largest inter-line time gaps to report |
| `--signals` | `###!,###,!!!,##@,@@@,***,=-=` | High-signal Lua message prefixes |
| `--json` | — | Emit JSON instead of text |
| `--no-color` | — | Disable ANSI colors |
| `--milestones` | — | Print the milestone ladder and exit |

## What is pmc_blackbox.log?

The `pmc_blackbox.log` is a real-time diagnostic stream emitted by `pmc_bb.dll` (the Mercenaries 2 PC instrumentation layer). It records:

- **Startup**: Shell bootstrap, movie playback, precache
- **Load**: World entity construction, streaming, portal enables
- **Gameplay**: Mission flow, job imports, entity updates
- **Diagnostics**: Texture-pool health, allocator stalls, crash context

Every line is timestamped `[HH:MM:SS.mmm]` and tagged with a source `[lua]`, `[crash]`, etc. Lua lines carry script location `@script:line`.

## Crash EIP Database

loadprobe maintains a database of known crash sites mapped to suspected subsystems. When a crash occurs, the EIP is looked up to provide context. New crashes are flagged as "UNRECOGNIZED — add to KNOWN_EIPS".

Current known crashes:

- **0x0061981F**: MTRL multi-material array overrun (FIXED 2026-06-16)
- **0x00874E7D**: Texture-streaming worker fault on process teardown (hard-close artifact)
- **0x0047AA5C**: PRMG null render-handle
- **0x0047A7D8**: PRMG twin pass / binding-array
- **0x0084DD5B**: MTRL texture-handle overrun
- **0x004CC064**: Render/texture-component pool NULL-fallback
- **0x007E045E**: ECS texture-component type-confusion

## Module Hierarchy

```
loadprobe/
├── src/
│   ├── main.rs        CLI entry point, argument parsing, verdict-based exit codes
│   ├── parse.rs       LogLine struct + parse_log() for timestamped log format
│   ├── phases.rs      Milestone ladder, known EIPs, source tags
│   ├── report.rs      Report struct, analysis, JSON/text output
│   └── sha256.rs      Minimal SHA-256 (FIPS 180-4) for log identity
├── tests/
│   └── fixtures.rs    Integration tests against real game logs
├── Cargo.toml
├── LICENSE.md
└── README.md
```

## Testing

Run all tests (including fixtures from `storage/` if available):

```bash
cargo test --all-features
```

Run unit tests only (no storage fixtures):

```bash
cargo test --lib
```

Test coverage > 90% across:

- Log parsing (timestamps, script tags, midnight wraps)
- Phase detection and milestone matching
- Crash EIP classification (known vs. new crashes)
- Report generation (JSON + text paths)
- Edge cases (truncated logs, malformed lines, missing phases)

## License

MIT License. See `LICENSE.md` for details.

## Contributing

Contributions are welcome. Please ensure:

- All tests pass: `cargo test`
- Code is formatted: `cargo fmt`
- No clippy warnings: `cargo clippy`
- Docs are up-to-date

## Support

For issues, feature requests, or to add new crash EIPs to the database, open an issue or contact the maintainers.
