#!/usr/bin/env node
/** MCP server exposing the LanceDB corpus index over stdio. */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { search, xref, getDoc, coverage, callgraph, stats, status, clearCaches } from './search.js';
import { ingest } from './ingest.js';
import { SOURCES } from './config.js';

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
    'persistent memory, past Claude conversations, tools/mods source, commit messages, and the 27k-function Ghidra ' +
    'decompilation of the unpacked exe. Use this FIRST when asking "what do we already know about X" before re-deriving anything. ' +
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
    'Exact cross-reference of a PC engine address across the ENTIRE corpus, regardless of spelling ' +
    '(FUN_00478120 == 0x478120 == 0x00478120). Returns every doc/memory/conversation/commit/decomp chunk mentioning it, ' +
    'grouped by source — i.e. "everything we have ever written down about this function/global".',
  inputSchema: {
    ref: z.string().describe('FUN_/DAT_/LAB_ symbol or hex address'),
    sources: sourcesParam,
    limit: z.number().int().min(1).max(200).default(40),
  },
}, async ({ ref, sources, limit }) => {
  try { return json(await xref({ ref, sources, limit })); } catch (e) { return err(e); }
});

server.registerTool('corpus_get', {
  title: 'Get corpus document',
  description:
    'Fetch the chunks of one indexed document by its corpus path (as returned by corpus_search/corpus_xref), ' +
    "e.g. 'docs/modernization/world_streaming_spec.md', 'ghidra/FUN_00478120', 'memory/....md', 'conversations/<session>.jsonl'. " +
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
    'Report which of the ~27k decompiled functions are referenced anywhere else in the corpus (docs, memory, ' +
    'conversations, annotations, commits) and which are still unnamed/undocumented. The uncovered list — sorted by ' +
    'function size or caller count — is the work queue for naming the remaining assembly surfaces.',
  inputSchema: {
    top: z.number().int().min(1).max(500).default(30).describe('how many uncovered functions to list'),
    sort: z.enum(['size', 'callers']).default('size'),
    prefix: z.string().optional().describe("only functions whose address starts with this hex prefix, e.g. '0047'"),
  },
}, async ({ top, sort, prefix }) => {
  try { return json(await coverage({ top, sort, prefix })); } catch (e) { return err(e); }
});

server.registerTool('corpus_callgraph', {
  title: 'Call-graph neighborhood of a function',
  description:
    'Walk the decompiled call graph (callers/callees extracted from the Ghidra dump) outward from a function, ' +
    'depth-limited BFS. Every node is annotated with which corpus sources already document it — so you can see, e.g., ' +
    '"FUN_00478120\'s callees are all named except these two", which is how unnamed functions inherit context for naming.',
  inputSchema: {
    ref: z.string().describe('FUN_ symbol or hex address to start from'),
    direction: z.enum(['callers', 'callees', 'both']).default('both'),
    depth: z.number().int().min(1).max(4).default(2),
    max_nodes: z.number().int().min(10).max(500).default(150),
  },
}, async ({ ref, direction, depth, max_nodes }) => {
  try { return json(await callgraph({ ref, direction, depth, maxNodes: max_nodes })); } catch (e) { return err(e); }
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
    'prefer running `npm run ingest` in tools/corpus_mcp for those.',
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

const transport = new StdioServerTransport();
await server.connect(transport);
console.error('[corpus-mcp] serving on stdio');
