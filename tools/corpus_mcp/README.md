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
| `ghidra` | **one doc per (image, function VA)** across every analysed executable image: names (Ghidra's + `exemap annotate`'s, with sources), block, size, thunk target, full caller/callee lists, cross-image translations, decompilation | `output/_ghidra_exports/<image_id>.functions.jsonl` + `<image_id>.annotate.jsonl`, checked against `tools/wad_simulator/crates/mercs2_exemap/data/images.tsv` |
| `lua_api` | **one row per Lua class/data module** with inherit chain, imports, methods, call sites, config fields read, and the data-table shape + records; plus one row per record_map record | `tools/wad_simulator/workshop_data/lua/**`, `tools/wad_simulator/workshop_data/shipments/**` |

Deliberately **not** indexed: binary assets (`output/`, `game-files/`,
WAD/block dumps), generated logs, `backups/`, vendored toolchains
(`tools/external`, `x32dbg`, jdk, ghidra install), `output.zip`.
The topic-specific decomp excerpts in `output/_ghidra/*.txt` are not indexed.

### The ghidra source (multi-image)

Every row of `images.tsv` is an executable image. A row with a `code_image` (a
regional build sharing another image's code byte for byte) has no export files;
it is listed in its code image's annotate `variants`, and every doc of the code
image carries it in the `images` column. Every other image needs both files in
`output/_ghidra_exports/`:

- `<image_id>.functions.jsonl` (Ghidra exporter) — an `image` record
  (`image_id`, `program`, `program_sha256`, `ghidra_version`, `language`,
  `compiler_spec`, `functions`), one `function` record per function (`va`,
  `name`, `name_source`, `block`, `size`, `thunk`, `thunk_target`, `callers`
  `[{site, function|null}]`, `callees` `["0x…" | "ext:<lib>!<name>" | "*0x…" |
  "*stack:<hex>" | "?" | "sys:<N>"]`, exactly one of `decomp` / `decomp_error`),
  and an `end` record (`functions`, `decompiled`, `failed`).
- `<image_id>.annotate.jsonl` (`exemap annotate`) — an `image` record
  (`image_id`, `sha256`, `variants`, `graph_images`, `untranslatable_images`),
  one record per function in the same order (`va`, `names [{name, source,
  detail}]`, `translations [{image, va, direct, answering_paths, paths}]`), and
  an `end` record (`functions`).

The whole set is verified before the table is touched: image ids, sha256 and
Ghidra language agree with `images.tsv` and between the two files, the files
hold the same functions in the same order with no repeated VA, the `end`
counts match, every record has exactly the contract's keys, and every
variant is listed by its code image and has no files of its own. Any
violation fails the ingest with the file, line and problem.

A code image with **neither** file is not exported yet: it is not indexed, the
ingest logs it (with its variants), and `corpus_status` lists it under
`sources.ghidra.images.notExported`. An image with only one of its two files is
a hard failure. `sources.ghidra.images` also lists `indexed` (chunks per
image), `exportedNotIndexed` and `changedSinceIngest` (export files newer than
the indexed rows); the last two count toward `stale`.

Doc path `ghidra/<image_id>/0x<va>`; title `<names joined with ' / '> @0x<va>
[<image_id>]`. The text is a header (names with sources, block, size, thunk
target, callers, callees, translations such as `x360-retail 0x8256… (direct,
3/5 paths)`) followed by the decompilation or `decompile failed: <reason>`.

## How it works

- **Embeddings**: `bge-small-en-v1.5` (384-dim) via transformers.js — local
  CPU, no API key; ~34MB model auto-downloaded to the HF cache on first run.
- **Search**: vector + BM25 full-text, merged with reciprocal-rank fusion, so
  both "how does hibernation streaming decide distances" *and* exact tokens
  like `FUN_00478120` / `0xE6B81A54` hit.
- **Addresses**: every chunk gets an `addrs` column — all `FUN_/DAT_/LAB_/0x`
  hex tokens normalized to 8 lowercase hex digits — so cross-references work
  regardless of spelling. `corpus_xref` matches the address as a whole token.
- **Call graph**: each ghidra row stores its full caller and callee lists in
  `meta`; the VA-to-function edges of one image → `corpus_callgraph` BFS.
- **Incremental**: unchanged files skipped by content hash; changed files
  reuse embeddings of unchanged chunks (`text_hash`); vanished docs deleted.
  Ghidra functions hash per function, so regenerating an export only re-embeds
  functions whose doc actually changed.

## Row schema

One LanceDB row per chunk. `ROW_COLUMNS` in `src/db.js` is the list; the
ingester writes exactly these columns.

| column | content |
|---|---|
| `id` | `path#chunk` |
| `source`, `path`, `title`, `chunk`, `text` | the doc and this chunk of it |
| `text_hash`, `file_hash` | chunk / doc content hashes (incremental skip + embedding reuse) |
| `mtime` | source file mtime (ms) |
| `image_id` | ghidra: the code image the row belongs to; **every other source: `''` (empty string)** |
| `image_sha256` | ghidra: that image's sha256; every other source: `''` |
| `va` | ghidra: function VA as `0x` + 8 lowercase hex digits; every other source: `''` |
| `images` | ghidra: space-separated code image + its variants; every other source: `''` |
| `addrs` | space-separated normalized address tokens found in the chunk |
| `meta` | JSON; ghidra: `names`, `block`, `size`, `thunk`, `thunk_target`, `callers`, `callees`, `translations`, `graph_images`, `untranslatable_images` (full lists); docs/memory: declared standing |
| `vector` | 384-dim embedding |

LanceDB takes a table's columns from the rows it was created with. When an
existing table's columns predate `ROW_COLUMNS`, the next ingest migrates them
in place (`migrateColumns` in `db.js`: add the image columns as `''`, drop
`fn_addr`), keeping every row and vector, so nothing is re-embedded; until
then every query fails with that instruction. A column difference with no
defined migration is a hard failure.

## Usage

```sh
cd tools/corpus_mcp
npm install
npm run ingest                       # everything (first run: hours, mostly ghidra+conversations)
node src/ingest.js --sources doc,memory   # just some sources
```

The MCP server is registered in the repo-root `.mcp.json`; Claude Code picks
it up automatically. CLI equivalents for humans:

```sh
node src/query.js search "wavelet skeletal animation decode" -k 5
node src/query.js search "buffer too small" --sources conversation
node src/query.js xref FUN_00478120 [--image pc-v11]
node src/query.js callgraph 0x478120 --image pc-v11 --dir callees --depth 2
node src/query.js coverage --image pc-v11 --top 40 --sort callers
node src/query.js translate pc-v11 0x478120 [--to x360-retail]
node src/query.js emit_stubs                                     # (re)generate EmmyLua stubs + .luarc.json
node src/query.js stats
```

## MCP tools

| tool | use |
|---|---|
| `corpus_search` | "what do we already know about X" — hybrid search, filter by `sources` / `path_prefix` |
| `corpus_xref` | every chunk anywhere mentioning an address (FUN_/0x spelling-independent, whole-token match); each hit carries `image_id` (`''` for prose); optional `image` keeps only that image's ghidra rows (a variant resolves to its code image) |
| `corpus_get` | pull full chunks of one doc by corpus path (`ghidra/<image_id>/0x<va>` for a function) |
| `corpus_callgraph` | BFS callers/callees of a function within one **required** `image`, nodes annotated with where the corpus documents them |
| `corpus_coverage` | which of one **required** `image`'s functions are documented anywhere vs unnamed — the naming work queue (prose mentions are address tokens with no image) |
| `corpus_translate` | one function's names and its translations to other images (`{image, va, to?}`), from the indexed row |
| `corpus_lua_api` | one class/data-module's inherit chain, imports, methods, call sites, config-field reads, table shapes + records |
| `corpus_lua_xref` | every call site / data-record match for a Lua symbol (`MrxTask.CreateChild`, `PmcBoss`, …) |
| `corpus_lua_callgraph` | BFS up/down the Lua class hierarchy from a root class |
| `corpus_lua_records` | filter a data-registry table by a flat `{field: value}` predicate |
| `corpus_lua_emit_stubs` | write EmmyLua `---@class` stubs for every shipped Lua class + data module into `tools/emmylua_stubs/mercs2/` and a `.luarc.json` at the repo root pointing sumneko at them |
| `corpus_stats` | chunk/doc counts per source |
| `ghidra_function` / `ghidra_decompile` / `ghidra_disassemble` / `ghidra_xrefs_to` / `ghidra_strings` / `ghidra_read_bytes` | live queries against an image's saved Ghidra project (see "Ghidra bridge") |
| `ghidra_rename_function` / `ghidra_set_comment` | edits to an image's Ghidra project; `reason` required, logged and saved before the answer |
| `ghidra_bridges` / `ghidra_bridge_stop` | the running bridges; stop one (releases its project for batch runs) |

### Ghidra bridge

`src/ghidra_bridge.js` keeps one headless Ghidra per image open between requests:
`scripts/ghidra_scripts/GhidraBridge.java` runs as the only postScript of a headless session on
the image's saved project (from `scripts/ghidra_projects.tsv`; analyzeHeadless from the
`ghidra_headless` key of `tools/wad_simulator/.mercs2-local.toml`) and serves newline-delimited
JSON over a Unix-domain socket. A bridge starts on the first `ghidra_*` call for its image (a few
seconds to open the project), then answers in milliseconds, and runs until `ghidra_bridge_stop` or
the server exits. A regional variant is served by its code image's bridge.

- **Edits** (`rename_function`, `set_comment`) need a `reason`, are appended to the project's
  `out/bridge_edits.tsv` (time, image, op, va, old, new, reason) and are committed and saved before
  the answer, so stopping or killing a bridge loses nothing. A renamed function shows the new name
  in the corpus only after the next export + annotate + ingest.
- **Locks**: a Ghidra project is locked by the process that opens it. Images sharing a project
  (ps3-v100 / ps3-v103-na) are served one at a time, and a batch headless run (export, fnsig) cannot
  open a project a bridge holds — stop the bridge first.
- **Failures** are errors naming the image, with the tail of the bridge's log
  (`out/bridge_<image>.log`): a run that exits or does not start listening in time, a request that
  times out (the bridge is then killed and the next request starts a new one), an error answer.

The index also speaks **LSP** over stdio: `npm run lsp` serves hover / goto-definition /
find-references / workspace-symbol / publishDiagnostics for the shipped Lua corpus, including
cross-file inherit-chain walks and the "which methods is my shim missing?" warning for
table-acts-as-class patterns. Wire it from VSCode via an extension that lets you register a
custom LSP binary (Neovim/Zed accept it natively); the LSP complements sumneko rather than
replacing it, so run both.


| `corpus_ingest` | incremental re-index from inside a session |

## The naming workflow this enables

1. `corpus_coverage --image <id> --sort callers` → biggest undocumented functions.
2. `corpus_callgraph <fn> --image <id>` → its neighborhood; documented neighbors give the
   subsystem context. `corpus_translate` → the same function in the other images.
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
