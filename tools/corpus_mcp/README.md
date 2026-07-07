# corpus_mcp — LanceDB corpus index + MCP server

Semantic + exact search over **everything this project knows**, so relevant
context can be surfaced instead of re-derived. One LanceDB table
(`storage/corpus_lancedb`, gitignored) holds embedded chunks from every corpus
edge, and an MCP server exposes search/xref/call-graph/coverage tools to
Claude Code.

## The corpus edges (what is indexed)

| source | what | where |
|---|---|---|
| `doc` | research docs, format specs, decompiled Lua corpora (`.md .lua .json .ini .cfg .txt`) | `docs/**` |
| `memory` | persistent Claude memory (one fact per file) | `~/.claude/projects/<proj>/memory/` |
| `conversation` | Claude Code session transcripts — user/assistant **text only**, tool noise stripped, windowed ~1800 chars | `~/.claude/projects/<proj>/*.jsonl` |
| `mod` | ASI mod sources | `mods/**` |
| `tool` | python probes, rust workspace, shell scripts, `mercs2_annotations.json`, Makefile | `tools/**`, `scripts/**`, `coopserver/**`, `tlsterm/**` |
| `project` | AGENTS.md, README, `.claude/skills` | repo root, `.claude/**` |
| `commit` | git commit messages, all branches | `git log --all` |
| `ghidra` | **one row per decompiled function** (27k) with size + caller/callee edge lists | `output/_ghidra/mercs2_unpacked.exe_decomp.txt` |

Deliberately **not** indexed: binary assets (`output/`, `game-files/`,
WAD/block dumps), generated logs, `backups/`, vendored toolchains
(`tools/external`, `x32dbg`, jdk, ghidra install), `output.zip`.
The topic-specific decomp excerpts in `output/_ghidra/*.txt` are subsets of
the full dump and are not double-indexed.

## How it works

- **Embeddings**: `bge-small-en-v1.5` (384-dim) via transformers.js — local
  CPU, no API key; ~34MB model auto-downloaded to the HF cache on first run.
- **Search**: vector + BM25 full-text, merged with reciprocal-rank fusion, so
  both "how does hibernation streaming decide distances" *and* exact tokens
  like `FUN_00478120` / `0xE6B81A54` hit.
- **Addresses**: every chunk gets an `addrs` column — all `FUN_/DAT_/LAB_/0x`
  hex tokens normalized to 8 lowercase hex digits — so cross-references work
  regardless of spelling.
- **Call graph**: each ghidra row stores its caller list (from the export
  header) and callee list (FUN_ refs in the body) → `corpus_callgraph` BFS.
- **Incremental**: unchanged files skipped by content hash; changed files
  reuse embeddings of unchanged chunks (`text_hash`); vanished docs deleted.
  Ghidra functions hash per-function, so regenerating the dump only re-embeds
  functions whose decompilation actually changed.

## Usage

```sh
cd tools/corpus_mcp
npm install
npm run ingest                       # everything (first run: ~1h, mostly ghidra+conversations)
node src/ingest.js --sources doc,memory   # just some sources
```

The MCP server is registered in the repo-root `.mcp.json`; Claude Code picks
it up automatically. CLI equivalents for humans:

```sh
node src/query.js search "wavelet skeletal animation decode" -k 5
node src/query.js search "buffer too small" --sources conversation
node src/query.js xref FUN_00478120
node src/query.js callgraph 0x478120 --dir callees --depth 2
node src/query.js coverage --top 40 --sort callers
node src/query.js stats
```

## MCP tools

| tool | use |
|---|---|
| `corpus_search` | "what do we already know about X" — hybrid search, filter by `sources` / `path_prefix` |
| `corpus_xref` | every chunk anywhere mentioning an address (FUN_/0x spelling-independent) |
| `corpus_get` | pull full chunks of one doc by corpus path |
| `corpus_callgraph` | BFS callers/callees of a function, nodes annotated with where the corpus documents them |
| `corpus_coverage` | which of the 27k functions are documented anywhere vs unnamed — the naming work queue |
| `corpus_stats` | chunk/doc counts per source |
| `corpus_ingest` | incremental re-index from inside a session |

## The naming workflow this enables

1. `corpus_coverage --sort callers` → biggest undocumented functions.
2. `corpus_callgraph <fn>` → its neighborhood; documented neighbors give the
   subsystem context.
3. `corpus_search` the decompiled body's distinctive strings/constants against
   `docs/mercs2-pdb-analysis` + `docs/mercs2-ecs` (Xbox symbol maps use
   different addresses, so the bridge is names/strings/semantics, not addrs).
4. Record the identification in `scripts/mercs2_annotations.json` /
   docs — the next ingest indexes it and coverage goes up.

## Keeping it fresh

Re-run `npm run ingest` after doc/annotation changes (seconds — hash-skip),
or let a session call `corpus_ingest {sources:['doc','memory','tool','commit']}`.
Conversations only need re-ingesting occasionally; the active session's
transcript changes constantly and is re-windowed each time.
