#!/usr/bin/env node
/** MCP server exposing the LanceDB corpus index over stdio. */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { search, xref, getDoc, coverage, callgraph, translate, luaApi, luaXref, luaCallgraph, luaRecords, stats, status, clearCaches, parseAddr } from './search.js';
import { ghidraRequest, stopBridge, listBridges, stopAllBridges, killAllBridges } from './ghidra_bridge.js';
import { ingest } from './ingest.js';
import { SOURCES } from './config.js';
import { emitAll as emitLuaStubs, writeLuarc } from './emmylua_emit.js';

const SOURCE_NAMES = Object.keys(SOURCES);

const server = new McpServer({ name: 'mercs2-corpus', version: '0.1.0' });

function json(data) {
  return { content: [{ type: 'text', text: JSON.stringify(data, null, 1) }] };
}
function err(e) {
  return { content: [{ type: 'text', text: `ERROR: ${e.message}` }], isError: true };
}

const sourcesParam = z.array(z.enum(SOURCE_NAMES)).optional()
  .describe(`restrict to these sources (${SOURCE_NAMES.join(', ')})`);

server.registerTool('corpus_search', {
  title: 'Search project corpus',
  description:
    'Hybrid semantic + keyword search over the whole Mercenaries 2 project corpus: research docs, decompiled Lua, ' +
    'persistent memory, past Claude conversations, tools/mods source, commit messages, and the Ghidra exports of every ' +
    'analysed executable image (PC / X360 / PS3; one row per image + function VA). Use this FIRST when asking "what do we already know about X" before re-deriving anything. ' +
    'Every hit carries `date`; transcripts are marked `unreviewed` and rank below written-up docs; documents may declare ' +
    '`status` (current/superseded/retracted), `evidence` (proven/inferred/speculative) and `supersedes` - prefer a current, ' +
    'proven, recent hit over an older one that merely sounds confident.',
  inputSchema: {
    query: z.string().describe('natural-language or keyword query'),
    k: z.number().int().min(1).max(50).default(8).describe('number of results'),
    sources: sourcesParam,
    path_prefix: z.string().optional().describe("restrict by path prefix, e.g. 'docs/mercs2-pdb-analysis'"),
    include_retracted: z.boolean().default(false)
      .describe('also return documents marked status:retracted (knowledge we tried and disproved) - hidden by default'),
  },
}, async ({ query, k, sources, path_prefix, include_retracted }) => {
  try {
    const results = await search({ query, k, sources, pathPrefix: path_prefix, includeRetracted: include_retracted });
    // Carry index freshness with every answer. A stale corpus returns yesterday's knowledge with
    // full confidence, which is indistinguishable from a correct answer at the moment it matters.
    let index;
    try {
      const st = await status();
      if (st.stale) index = { stale: true, changedSinceIngest: st.changedSinceIngest, hint: st.hint };
    } catch { /* freshness is advisory - never fail a search over it */ }
    return json(index ? { index, results } : { results });
  } catch (e) { return err(e); }
});

server.registerTool('corpus_status', {
  title: 'Index freshness',
  description:
    'Is the corpus index up to date? Per source: indexed chunk count, newest indexed date, and how many files on ' +
    'disk have changed since the last ingest (with examples). Use when a search result looks older than something ' +
    'you know was just written - a silently stale index is why freshly-recorded knowledge appears to not exist.',
  inputSchema: {
    force: z.boolean().default(false).describe('bypass the 30s freshness cache'),
  },
}, async ({ force }) => {
  try { return json(await status({ force })); } catch (e) { return err(e); }
});

server.registerTool('corpus_xref', {
  title: 'Cross-reference an engine address',
  description:
    'Exact cross-reference of an engine address across the ENTIRE corpus, regardless of spelling ' +
    '(FUN_00478120 == 0x478120 == 0x00478120; matched as a whole address token). Returns every ' +
    'doc/memory/conversation/commit/decomp chunk mentioning it, grouped by source; every hit carries its image_id ' +
    "('' for prose, which is not attributed to an image). Pass `image` to keep only that image's Ghidra rows " +
    '(a regional variant resolves to its code image).',
  inputSchema: {
    ref: z.string().describe('FUN_/DAT_/LAB_ symbol or hex address'),
    image: z.string().optional().describe("images.tsv image_id, e.g. 'pc-v11' — restricts to that image's ghidra rows"),
    sources: sourcesParam,
    limit: z.number().int().min(1).max(200).default(40),
  },
}, async ({ ref, image, sources, limit }) => {
  try { return json(await xref({ ref, image, sources, limit })); } catch (e) { return err(e); }
});

server.registerTool('corpus_get', {
  title: 'Get corpus document',
  description:
    'Fetch the chunks of one indexed document by its corpus path (as returned by corpus_search/corpus_xref), ' +
    "e.g. 'docs/modernization/world_streaming_spec.md', 'ghidra/pc-v11/0x00478120', 'memory/....md', 'conversations/<session>.jsonl'. " +
    'Pass chunk+context to get a window instead of the whole doc.',
  inputSchema: {
    path: z.string(),
    chunk: z.number().int().min(0).optional().describe('center chunk index'),
    context: z.number().int().min(0).max(10).default(1).describe('neighboring chunks each side'),
  },
}, async ({ path, chunk, context }) => {
  try { return json(await getDoc({ path, chunk, context })); } catch (e) { return err(e); }
});

server.registerTool('corpus_coverage', {
  title: 'Decompilation naming coverage',
  description:
    "Report which of one image's decompiled functions are referenced anywhere else in the corpus (docs, memory, " +
    'conversations, annotations, commits) and which are still unnamed/undocumented. The uncovered list — sorted by ' +
    'function size or caller count — is the work queue for naming the remaining assembly surfaces. A prose mention is ' +
    'an address token with no image, so it counts for whichever image has a function at that VA.',
  inputSchema: {
    image: z.string().describe("images.tsv image_id, e.g. 'pc-v11' (a variant resolves to its code image)"),
    top: z.number().int().min(1).max(500).default(30).describe('how many uncovered functions to list'),
    sort: z.enum(['size', 'callers']).default('size'),
    prefix: z.string().optional().describe("only functions whose address starts with this hex prefix, e.g. '0047'"),
  },
}, async ({ image, top, sort, prefix }) => {
  try { return json(await coverage({ image, top, sort, prefix })); } catch (e) { return err(e); }
});

server.registerTool('corpus_callgraph', {
  title: 'Call-graph neighborhood of a function',
  description:
    "Walk one image's call graph (direct caller/callee edges from the Ghidra export) outward from a function, " +
    'depth-limited BFS. Every node is annotated with which corpus sources already document it — so you can see, e.g., ' +
    '"FUN_00478120\'s callees are all named except these two", which is how unnamed functions inherit context for naming.',
  inputSchema: {
    image: z.string().describe("images.tsv image_id, e.g. 'pc-v11' (a variant resolves to its code image)"),
    ref: z.string().describe('FUN_ symbol or hex address to start from'),
    direction: z.enum(['callers', 'callees', 'both']).default('both'),
    depth: z.number().int().min(1).max(4).default(2),
    max_nodes: z.number().int().min(10).max(500).default(150),
  },
}, async ({ image, ref, direction, depth, max_nodes }) => {
  try { return json(await callgraph({ image, ref, direction, depth, maxNodes: max_nodes })); } catch (e) { return err(e); }
});

server.registerTool('corpus_translate', {
  title: 'Translate a function to other images',
  description:
    "One function's names (Ghidra's plus every name `exemap annotate` attached, with sources) and its translations " +
    'to the same function in other executable images (target VA, direct or not, answering/total paths), read from ' +
    "the indexed row. `to` keeps only translations into that image. Also returns the source image's graph_images and " +
    'untranslatable_images as exemap reported them.',
  inputSchema: {
    image: z.string().describe("images.tsv image_id the VA belongs to, e.g. 'pc-v11'"),
    va: z.string().describe('function address (FUN_00478120, 0x478120, …)'),
    to: z.string().optional().describe("keep only translations into this image_id, e.g. 'x360-retail'"),
  },
}, async ({ image, va, to }) => {
  try { return json(await translate({ image, va, to })); } catch (e) { return err(e); }
});

server.registerTool('corpus_lua_api', {
  title: 'Lua class / data-module API surface',
  description:
    'Static Lua analysis for one class, data module, or table that acts as a class via ' +
    '`function T.M(self)` definitions. For a class (`inherit`-rooted module like ' +
    '`MrxTaskObjective`): returns inherit chain, imports, methods defined, calls on `self` / ' +
    '`super` / `self:GetMissionAncestor()` / `self:GetParent()`, config fields read from ' +
    '`self:GetConfig()`, and imported data-table references. For a data module ' +
    '(`WifMissionData`, `WifStarterData`, …): returns every top-level table with its inferred ' +
    'shape (`record_map` / `ordered_list` / `scalar` / `nested`), union record schema with ' +
    'Hungarian-prefix-inferred types, and the records themselves (literal fields only; nested ' +
    'tables summarised). A table that declares methods via `function T.M(self)` form (common in ' +
    'mod shims that parent engine primitives) has those defs collected under `methods_defined` ' +
    'keyed by receiver — making `calls_on_mission_ancestor` ∖ `methods_defined` the ' +
    'duck-typed-contract gap query.',
  inputSchema: {
    name: z.string().describe('class name, data module, file basename, or table-as-class name'),
    resolve_chain: z.boolean().default(true)
      .describe('for classes: also walk `inherit()` ancestors and attach their `methods_defined` as `inherited_methods`'),
  },
}, async ({ name, resolve_chain }) => {
  try { return json(await luaApi({ name, resolve_chain })); } catch (e) { return err(e); }
});

server.registerTool('corpus_lua_xref', {
  title: 'Cross-reference a Lua symbol',
  description:
    'Find every call site, super-call, imported-module-field read, or data-record field value ' +
    'that references a Lua symbol anywhere in the shipped+mod Lua corpus. Accepts qualified ' +
    '("MrxTask.CreateChild") or bare ("CreateChild") symbol forms, plus string-literal values ' +
    '("PmcBoss" finds every mission with sStarter=PmcBoss AND every _AddIntro("PmcBoss",...) ' +
    'call site). Backed by the same AST index as corpus_lua_api.',
  inputSchema: {
    symbol: z.string().describe('qualified "Module.Method", bare "Method", or literal value'),
    limit: z.number().int().min(1).max(500).default(100),
  },
}, async ({ symbol, limit }) => {
  try { return json(await luaXref({ symbol, limit })); } catch (e) { return err(e); }
});

server.registerTool('corpus_lua_callgraph', {
  title: 'Walk the Lua class graph',
  description:
    'BFS over the shipped Lua class hierarchy from a root class, following inherit() edges. ' +
    '`direction` picks parents / children / both. Returns nodes with their method count + ' +
    'edges labelled by kind. Mirrors corpus_callgraph for the Lua side of the project.',
  inputSchema: {
    root: z.string().describe('class name (`MrxTaskContract`, `mrxtaskobjective`, …)'),
    direction: z.enum(['parents', 'children', 'both']).default('both'),
    depth: z.number().int().min(1).max(6).default(2),
    max_nodes: z.number().int().min(10).max(500).default(150),
  },
}, async ({ root, direction, depth, max_nodes }) => {
  try { return json(await luaCallgraph({ root, direction, depth, maxNodes: max_nodes })); } catch (e) { return err(e); }
});

server.registerTool('corpus_lua_records', {
  title: 'Filter records in a Lua data table',
  description:
    'Query a shipped Lua data registry (`WifMissionData.tMissionData`, `WifStarterData.*`, …) ' +
    'with a flat scalar-field predicate: `{sStarter: "PmcBoss"}` returns every record whose ' +
    'sStarter is literally that string. Equality only; nested-table fields are not filterable. ' +
    'Use corpus_lua_api <module> first to see available tables and their record schemas.',
  inputSchema: {
    module: z.string().describe('module name as reported by corpus_lua_api (e.g. `wifmissiondata`)'),
    table: z.string().describe('top-level table within the module (e.g. `tMissionData`)'),
    where: z.record(z.union([z.string(), z.number(), z.boolean()])).default({})
      .describe('{field: value} predicate; all must match'),
  },
}, async ({ module, table, where }) => {
  try { return json(await luaRecords({ module, table, where })); } catch (e) { return err(e); }
});

server.registerTool('corpus_lua_emit_stubs', {
  title: 'Emit EmmyLua stubs for shipped Lua classes + data modules',
  description:
    'Writes one `---@class` stub per shipped Lua class (with inherit chain, config fields and ' +
    'methods), one per data module (with record-shape classes for each record_map table), and ' +
    'a `.luarc.json` at the repo root that wires sumneko.lua at the stub libraries. Idempotent; ' +
    'safe to re-run after `corpus_ingest --sources lua_api`. Stubs are Hungarian-prefix typed ' +
    '(b*/n*/s*/t*/v*/f*/u*/o*).',
  inputSchema: {
    out_dir: z.string().optional()
      .describe('override output directory (default: tools/emmylua_stubs/mercs2)'),
    write_luarc: z.boolean().default(true)
      .describe('also write .luarc.json at the repo root pointing sumneko at the stub libraries'),
    globals: z.array(z.string()).optional()
      .describe('global names to add to .luarc.json diagnostics.globals; defaults to the binding_map namespaces'),
  },
}, async ({ out_dir, write_luarc: wl, globals }) => {
  try {
    const emit = emitLuaStubs({ outDir: out_dir });
    let luarc;
    if (wl) {
      luarc = writeLuarc({ stubRoot: emit.outDir, globals: globals ?? emit.globals });
    }
    return json({ emit, luarc });
  } catch (e) { return err(e); }
});

server.registerTool('corpus_stats', {
  title: 'Corpus index stats',
  description: 'Chunk/document counts per source in the LanceDB corpus index.',
  inputSchema: {},
}, async () => {
  try { return json(await stats()); } catch (e) { return err(e); }
});

server.registerTool('corpus_ingest', {
  title: 'Re-ingest corpus sources',
  description:
    'Incrementally re-index sources into LanceDB (unchanged files are skipped via content hash). ' +
    'doc/memory/tool/mod/commit take seconds-to-minutes; conversation and ghidra can take much longer on first run — ' +
    'prefer running `npm run ingest` in tools/corpus_mcp for those. A table whose columns predate the current row ' +
    'shape is migrated in place first (rows and vectors kept).',
  inputSchema: {
    sources: sourcesParam,
    full: z.boolean().default(false).describe('ignore hash cache and re-embed everything'),
  },
}, async ({ sources, full }) => {
  try {
    const res = await ingest({ sources, full, log: () => {} });
    clearCaches();
    return json(res);
  } catch (e) { return err(e); }
});

// --- Ghidra bridge: live queries and edits against an image's saved Ghidra project -----------
// One headless Ghidra per image starts on the first ghidra_* call for it (a project open takes
// seconds to a minute) and stays up until ghidra_bridge_stop or server exit. While a bridge holds
// an image's project, batch headless runs on it (export, fnsig) cannot open it.

const imageParam = z.string().describe("images.tsv image_id, e.g. 'pc-v10' (a regional variant is served by its code image)");
const vaParam = z.string().describe('address (FUN_00478120, 0x478120, ...)');
const va = (ref) => `0x${parseAddr(ref)}`;
const BRIDGE_NOTE = ' Answers come from the live Ghidra project, so they reflect edits made since the last export; the corpus ' +
  'rows change only after the next export + annotate + ingest.';

function bridgeTool(name, title, description, inputSchema, toRequest) {
  server.registerTool(name, { title, description: description + BRIDGE_NOTE, inputSchema }, async (args) => {
    try {
      const [op, params] = toRequest(args);
      return json(await ghidraRequest(args.image, op, params));
    } catch (e) { return err(e); }
  });
}

bridgeTool('ghidra_function', 'Function facts (live Ghidra)',
  'The function containing an address: entry, name and its source, signature, body ranges, thunk target, every caller ' +
  '(site + calling function) and its call list (the FnMnemonicSig grammar: 0x… direct, ext:<lib>!<name>, *0x… slot, ' +
  '*stack:<off>, ?, sys:<N>).',
  { image: imageParam, va: vaParam }, (a) => ['function', { va: va(a.va) }]);

bridgeTool('ghidra_decompile', 'Decompile (live Ghidra)',
  'Decompiled C of the function containing an address (c, or error when the decompiler fails).',
  { image: imageParam, va: vaParam }, (a) => ['decompile', { va: va(a.va) }]);

bridgeTool('ghidra_disassemble', 'Disassemble (live Ghidra)',
  'Instructions (va, bytes, text): the whole function containing va, or `count` instructions starting at va.',
  { image: imageParam, va: vaParam, count: z.number().int().min(1).max(4000).optional().describe('instructions from va instead of the whole function') },
  (a) => ['disassemble', a.count === undefined ? { va: va(a.va) } : { va: va(a.va), count: a.count }]);

bridgeTool('ghidra_xrefs_to', 'References to an address (live Ghidra)',
  'Every reference to an address: from, reference type, and the function containing the reference (or null).',
  { image: imageParam, va: vaParam }, (a) => ['xrefs_to', { va: va(a.va) }]);

bridgeTool('ghidra_strings', 'Search defined strings (live Ghidra)',
  'Defined strings matching a Java regex (find), each with the functions that reference it; `truncated` says more matched than `limit`.',
  { image: imageParam, regex: z.string().min(1), limit: z.number().int().min(1).max(2000).default(200) },
  (a) => ['strings', { regex: a.regex, limit: a.limit }]);

bridgeTool('ghidra_read_bytes', 'Read bytes (live Ghidra)',
  'Raw bytes at an address, as hex.',
  { image: imageParam, va: vaParam, length: z.number().int().min(1).max(65536) },
  (a) => ['read_bytes', { va: va(a.va), length: a.length }]);

bridgeTool('ghidra_rename_function', 'Rename a function (writes the Ghidra project)',
  'Rename the function whose entry is va. The reason (the evidence for the name) is required and goes to the ' +
  "project's out/bridge_edits.tsv ledger with the old and new name; the program is saved before this returns.",
  { image: imageParam, va: vaParam, name: z.string().min(1), reason: z.string().min(1).describe('the evidence for the name') },
  (a) => ['rename_function', { va: va(a.va), name: a.name, reason: a.reason }]);

bridgeTool('ghidra_set_comment', 'Set a comment (writes the Ghidra project)',
  "Set a pre/post/eol/plate/repeatable comment at an address. The reason is required and goes to the project's " +
  'out/bridge_edits.tsv ledger with the old and new text; the program is saved before this returns.',
  {
    image: imageParam, va: vaParam,
    kind: z.enum(['pre', 'post', 'eol', 'plate', 'repeatable']),
    text: z.string().min(1), reason: z.string().min(1).describe('why the comment is true'),
  },
  (a) => ['set_comment', { va: va(a.va), kind: a.kind, text: a.text, reason: a.reason }]);

server.registerTool('ghidra_bridges', {
  title: 'Running Ghidra bridges',
  description: 'The Ghidra bridges this server started: image, project, program, pid, request count, state, ledger and log paths.',
  inputSchema: {},
}, async () => {
  try { return json(listBridges()); } catch (e) { return err(e); }
});

server.registerTool('ghidra_bridge_stop', {
  title: 'Stop a Ghidra bridge',
  description: "Stop the bridge serving an image (its headless run saves and exits), releasing the image's Ghidra project " +
    'for batch runs (export, fnsig).',
  inputSchema: { image: imageParam },
}, async ({ image }) => {
  try { return json(await stopBridge(image)); } catch (e) { return err(e); }
});

for (const sig of ['SIGINT', 'SIGTERM']) {
  process.on(sig, () => {
    stopAllBridges().then(() => process.exit(0), (e) => { console.error(`[corpus-mcp] stopping bridges: ${e.message}`); process.exit(1); });
  });
}
process.stdin.on('end', () => {
  stopAllBridges().then(() => process.exit(0), (e) => { console.error(`[corpus-mcp] stopping bridges: ${e.message}`); process.exit(1); });
});
process.on('exit', killAllBridges);

const transport = new StdioServerTransport();
await server.connect(transport);
console.error('[corpus-mcp] serving on stdio');
