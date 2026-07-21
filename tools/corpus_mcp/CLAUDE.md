# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

`README.md` is the user-facing reference (the corpus edges, the naming workflow, the MCP tool table). Read it first. This file adds the internals a change touches across several source files.

## Commands

Run from `tools/corpus_mcp/`:

```sh
npm install                                   # deps: transformers.js, lancedb, mcp sdk, zod
npm run ingest                                # (re)index all sources; incremental via hash-skip
node src/ingest.js --sources doc,memory,tool  # only some sources
node src/ingest.js --full                     # ignore hash cache, re-embed everything

node src/query.js search "hibernation streaming distances" -k 5   # CLI smoke test
node src/query.js xref FUN_00478120
node src/query.js callgraph 0x478120 --dir callees --depth 2
node src/query.js coverage --top 40 --sort callers
node src/query.js stats

node src/server.js                            # the MCP server (stdio); normally launched via .mcp.json

npm test                                      # full suite (node:test); includes the e2e pipeline
npm run test:unit                             # pure-function + config tests only (no model needed)
CORPUS_SKIP_INTEGRATION=1 npm test            # skip the embedding-backed e2e test
```

No linter, no build step — pure ESM Node (`"type": "module"`), run directly. Tests use the built-in `node:test` runner (no dependency); files live in `test/*.test.js`.

There is no way to add or verify data other than `ingest`; if search/xref returns nothing, the first check is whether that source has been ingested (`node src/query.js stats`).

## Architecture

One LanceDB table named `corpus` at `../../storage/corpus_lancedb` (repo-root-relative, gitignored). Everything is a **row = one chunk**; a **document = one ingestion unit** (a file, a conversation, a commit, or a single decompiled function) that expands into N chunk rows.

Data flow, one file per stage:

```
config.js SOURCES  →  sources.js allDocs()  →  ingest.js  →  db.js (LanceDB)  →  search.js  →  server.js (MCP) / query.js (CLI)
 (the 8 edges)        (per-source walkers)     (hash-skip,                        (hybrid RRF,
                                                embed, upsert)                    graph, coverage)
```

- **`config.js`** — the single source of truth for what exists: `SOURCES` (the 8 edges and how each is walked), paths (`DB_PATH`, `TRANSCRIPTS_DIR` computed from the Claude-Code project-dir encoding of the repo root), the embedding model, and chunk sizes. Adding a source or changing an exclude list happens here. Every scalar is overridable via a `CORPUS_*` env var (see `.env.example`); `env.js` loads `tools/corpus_mcp/.env` at import, but a real process env var always wins over the file. Point `CORPUS_REPO_ROOT` at another tree to reuse the whole tool on a different project.
- **`sources.js`** — one generator per source shape: `fileDocs` (doc/mod/tool/project trees), `memoryDocs`, `conversationDocs`, `commitDocs`, `ghidraDocs`. `allDocs(names)` dispatches. Each yields the uniform doc shape `{ source, path, title, mtime, fileHash, chunks[], fnAddr?, meta? }`.
- **`chunk.js`** — chunking + address handling, shared by ingest and search. Three chunkers picked by extension: `chunkMarkdown` (prefixes each chunk with its nearest heading), `chunkCode` (line-window with overlap), `chunkText` (paragraph-boundary). `normAddr`/`extractAddrs` power cross-referencing (see below).
- **`ingest.js`** — the incremental engine. `search.js` — all query logic. `server.js` — thin MCP wrapper (each tool = try/catch → `search.js` fn → JSON). `query.js` — the same functions behind a CLI. `db.js` — LanceDB connection + the `esc()` SQL-quote helper.

### Row schema (implicit, defined by the object built in `ingest.js`)

`id` (`path#chunkIndex`), `source`, `path`, `title`, `chunk`, `text`, `text_hash`, `file_hash`, `mtime`, `fn_addr`, `addrs`, `meta`, `vector` (384-dim). No migration tooling — changing this shape means re-ingesting `--full`.

### Cross-referencing engine addresses

The `addrs` column is a space-delimited list of every `FUN_/DAT_/LAB_/SUB_/0x` token in the chunk, each normalized to **8 lowercase hex digits** (`normAddr`). This is why `FUN_00478120`, `0x478120`, and `0x00478120` all match the same `xref`/`callgraph` result — matching is on the normalized token via `LIKE '%<addr>%'`, not on the spelling. Any new address-bearing text is only discoverable if `extractAddrs` runs over it at ingest.

### Incremental strategy (three hash levels)

1. **Document skip** — a doc whose `(path, file_hash)` already matches the table is untouched. Changed docs are delete-then-reinsert.
2. **Chunk-embedding reuse** — within a changed doc, chunks whose `text_hash` is unchanged reuse the stored `vector` instead of re-embedding (embedding is the expensive step).
3. **Cheap identity for big inputs** — conversation `file_hash` is `sha256("size:mtime")`, not a content hash (transcripts are huge and grow constantly). Ghidra hashes **per-function body**, so regenerating the 27k-function dump only re-embeds functions whose decompilation actually changed.

Docs that vanished from a source are deleted at the end (paths seen this run vs. paths in the table).

### Hybrid search (`search.js`)

Vector search (`vectorSearch` over the bge embedding) and BM25 full-text (`fullTextSearch`) are run separately, then merged with **reciprocal-rank fusion** (`1/(60+rank)` summed per id). This is what lets one query surface both a semantic paraphrase and an exact token like `FUN_00478120` or a hash. FTS silently degrades to vector-only if the index isn't built yet — `ingest.js` (re)builds the FTS index on `text` after any change.

### Ghidra as a call graph

`ghidraDocs` parses the dump with `FN_HEADER_RE` (`==== NAME @0xADDR size=N callers=[...]`). **Callers** come from the header; **callees** are the `FUN_` refs found in the body (minus self). Both are stored (normalized) in the chunk-0 `meta` JSON. `coverage`/`callgraph` in `search.js` load only chunk-0 rows into in-process `fnCache`/`mentionCache` (address → which non-ghidra sources mention it) and walk the graph there. Those caches are module-level and are cleared via `clearCaches()` after any in-session `corpus_ingest`, otherwise coverage would go stale.

### Embeddings

`bge-small-en-v1.5` (384-dim) via transformers.js, local CPU, no API key (~34 MB model downloaded to the HF cache on first use). bge wants a query prefix (`QUERY_PREFIX`) on **queries only** — `embed.js` exposes `embedQuery` vs `embedPassages` for exactly this asymmetry; don't cross them.

## Conventions

- Keep `SOURCES` in `config.js` and the README's "corpus edges" table in sync — the README documents what `config.js` declares.
- New MCP tools: register in `server.js`, implement in `search.js`, mirror in `query.js` so there's always a CLI path for humans to reproduce a result.
- SQL predicates are built by string interpolation; always route user/path strings through `esc()` (`db.js`).
