# Changelog

All notable changes to loadprobe are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-06-18

### Added

- **Stable CLI interface**: All core arguments now finalized and stable across releases
  - `--routine`: Customize routine sources (default: lua, pool)
  - `--hang-secs`: Tune hang detection threshold (default: 10s)
  - `--top-gaps`: Report largest inter-line time gaps (default: 5)
  - `--signals`: High-signal Lua message prefixes (default: ###!, ###, !!!, ##@, @@@, ***, =-=)
  - `--json`: Machine-readable output
  - `--no-color`: Disable ANSI colors
  - `--milestones`: Print the milestone ladder and exit

- **Comprehensive test coverage**: 90%+ test coverage across
  - Log parsing (timestamps, script tags, midnight wraps, edge cases)
  - Phase detection and milestone matching
  - Crash EIP classification and known-EIP database
  - Report generation (JSON and text output)
  - Stream aggregation, pool health analysis, and gap detection

- **Documentation**: Full README, inline module docs, and function-level documentation

- **Metadata**: Package description, license (MIT), repository URL, keywords, categories

- **Known crash database**: 7 documented crash sites with subsystem labels

- **Integration tests**: 4 real log fixtures (vanilla boot, hangs, truncations) with locked verdicts

### Fixed

- Dependency versions now pinned (clap 4.5, colored 2.1, serde 1.0, serde_json 1.0)
- Midnight wrap correction in timestamp parsing (confirmed via tests)
- Teardown EIP classification (0x874E7D and similar hard-close artifacts no longer falsely rated as crashes)
- Pool refill detection and burst reporting

### Known Limitations

- Fixtures in `storage/` are read-only for CI; manual log runs populate them
- SHA-256 implementation is minimal (no streaming) — suitable for logs < 1 GB
- ANSI color output unavailable on platforms without `colored` support

## [0.1.0] — Initial Release

- Basic log parsing and phase detection
- Crash dump reporting
- Text and JSON output modes
