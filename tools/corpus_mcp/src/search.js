import { openTable, esc } from './db.js';
import { embedQuery } from './embed.js';
import { normAddr } from './chunk.js';
import { sourceFreshness } from './sources.js';

function sourceFilter(sources, pathPrefix) {
  const parts = [];
  if (sources?.length) parts.push(`source IN (${sources.map((s) => `'${esc(s)}'`).join(',')})`);
  if (pathPrefix) parts.push(`path LIKE '${esc(pathPrefix)}%'`);
  return parts.join(' AND ') || null;
}

async function requireTable() {
  const table = await openTable();
  if (!table) throw new Error('corpus table does not exist yet — run the ingester first (npm run ingest in tools/corpus_mcp)');
  return table;
}

const RESULT_COLS = ['id', 'source', 'path', 'title', 'chunk', 'text', 'fn_addr', 'meta', 'mtime'];

/**
 * Per-source authority, applied as a multiplier on the fusion score.
 *
 * Rank fusion alone treats every source as equally trustworthy, which is false and was measurably
 * harmful: session transcripts are 6,427 chunks from 60 files (~19% of all non-Ghidra prose) and
 * were taking the top slot on 5 of 13 eval queries — including returning the transcript of a
 * FAILED session as the best answer to the very question that session got wrong. A transcript is
 * unreviewed thinking-out-loud: it records wrong turns, abandoned theories and self-corrections
 * with the same weight as the conclusion. It stays searchable (there are real derivations in
 * there that were never written up) but it must never outrank a written-up document.
 */
export const SOURCE_AUTHORITY = {
  doc: 1.0,        // written-up research
  memory: 1.0,     // curated one-fact-per-file
  project: 1.0,    // AGENTS.md / repo config
  ghidra: 1.0,     // the decompilation is ground truth
  tool: 0.9,       // source + READMEs: real, but incidental prose
  commit: 0.9,     // terse, and the diff is the real record
  mod: 0.9,
  conversation: 0.25, // unreviewed transcript
};

const UNREVIEWED = new Set(['conversation']);

/** Hybrid (vector + BM25) search merged with authority-weighted reciprocal-rank fusion. */
export async function search({ query, k = 8, sources, pathPrefix }) {
  const table = await requireTable();
  const filter = sourceFilter(sources, pathPrefix);
  // Fetch deeper than k: demotion reorders the list, so a doc that a transcript displaced out of
  // the top k must still be present to be promoted back into it.
  const fetchN = Math.max(k * 6, 40);

  let vq = table.vectorSearch(await embedQuery(query)).select(RESULT_COLS).limit(fetchN);
  if (filter) vq = vq.where(filter);
  const vres = await vq.toArray();

  let fres = [];
  try {
    let fq = table.query().fullTextSearch(query).select(RESULT_COLS).limit(fetchN);
    if (filter) fq = fq.where(filter);
    fres = await fq.toArray();
  } catch { /* no FTS index yet — vector-only */ }

  const scores = new Map();
  const byId = new Map();
  const K = 60;
  const bump = (r, i) => {
    const w = SOURCE_AUTHORITY[r.source] ?? 1.0;
    scores.set(r.id, (scores.get(r.id) ?? 0) + w / (K + i));
    byId.set(r.id, r);
  };
  vres.forEach(bump);
  fres.forEach(bump);

  return [...scores.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, k)
    .map(([id, score]) => ({ score: Number(score.toFixed(4)), ...pick(byId.get(id)) }));
}

/** `mtime` is stored at ingest but was never surfaced, so no result could be dated. */
function isoDate(mtime) {
  const ms = Number(mtime);
  if (!ms) return undefined;
  return new Date(ms).toISOString().slice(0, 10);
}

function pick(r) {
  return {
    id: r.id, source: r.source, path: r.path, title: r.title, chunk: r.chunk,
    date: isoDate(r.mtime),
    // Say it in the payload, not just in the source name: a reader skimming hits should not have
    // to know that `conversation` means "nobody checked this".
    unreviewed: UNREVIEWED.has(r.source) || undefined,
    fn_addr: r.fn_addr || undefined, text: r.text,
  };
}

/**
 * Index freshness: per source, newest indexed mtime vs newest on-disk mtime, and how many files
 * changed since the last ingest. Cached briefly so `search` can carry a warning without paying a
 * directory walk per query.
 */
let freshCache = { at: 0, value: null };
const FRESH_TTL_MS = 30_000;

export async function status({ force = false } = {}) {
  if (!force && freshCache.value && Date.now() - freshCache.at < FRESH_TTL_MS) return freshCache.value;
  const table = await openTable();
  if (!table) return { indexed: false, stale: true, reason: 'corpus table does not exist — run npm run ingest' };

  const rows = await table.query().select(['source', 'mtime']).toArray();
  const indexedNewest = {};
  const counts = {};
  for (const r of rows) {
    counts[r.source] = (counts[r.source] ?? 0) + 1;
    const m = Number(r.mtime) || 0;
    if (m > (indexedNewest[r.source] ?? 0)) indexedNewest[r.source] = m;
  }

  const disk = sourceFreshness(indexedNewest);
  const sources = {};
  let staleTotal = 0;
  for (const [name, d] of Object.entries(disk)) {
    const indexedAt = indexedNewest[name] ?? 0;
    const entry = {
      chunks: counts[name] ?? 0,
      indexedNewest: indexedAt ? new Date(indexedAt).toISOString().slice(0, 10) : null,
    };
    if (d.known) {
      entry.filesOnDisk = d.files;
      entry.changedSinceIngest = d.newerThanIndex;
      if (d.newerThanIndex > 0) { entry.examples = d.examples; staleTotal += d.newerThanIndex; }
    } else {
      entry.changedSinceIngest = null; // special walker (conversations/commits/ghidra) — not stat-able cheaply
    }
    sources[name] = entry;
  }

  const value = {
    indexed: true,
    stale: staleTotal > 0,
    changedSinceIngest: staleTotal,
    hint: staleTotal > 0 ? 'run `npm run ingest` in tools/corpus_mcp — results below may predate recent edits' : undefined,
    sources,
  };
  freshCache = { at: Date.now(), value };
  return value;
}

/** Invalidate the freshness cache (called after an in-session ingest). */
export function clearFreshness() { freshCache = { at: 0, value: null }; }

/** Exact cross-reference: every chunk in the corpus mentioning an address,
 *  regardless of spelling (FUN_00478120, 0x478120, 0x00478120...). */
export async function xref({ ref, sources, limit = 40 }) {
  const table = await requireTable();
  const m = String(ref).match(/([0-9a-fA-F]{5,8})\s*$/);
  if (!m) throw new Error(`could not parse an address out of '${ref}' — pass FUN_00478120, 0x478120, or a hex address`);
  const addr = normAddr(m[1]);
  let q = table.query().where(
    [`addrs LIKE '%${addr}%'`, sourceFilter(sources, null)].filter(Boolean).join(' AND '),
  ).select(RESULT_COLS).limit(limit);
  const rows = await q.toArray();
  // Group by source for a readable coverage picture.
  const groups = {};
  for (const r of rows) (groups[r.source] ??= []).push(pick(r));
  return { addr: `0x${addr}`, mentions: rows.length, bySource: groups };
}

/** All chunks of one document (optionally a window around one chunk). */
export async function getDoc({ path, chunk, context = 1 }) {
  const table = await requireTable();
  let where = `path = '${esc(path)}'`;
  if (chunk !== undefined && chunk !== null)
    where += ` AND chunk >= ${Math.max(0, chunk - context)} AND chunk <= ${chunk + context}`;
  const rows = await table.query().where(where).select(RESULT_COLS).limit(200).toArray();
  rows.sort((a, b) => a.chunk - b.chunk);
  return rows.map(pick);
}

// In-process caches for the graph/coverage scans (cleared after ingest).
let fnCache = null;       // fn_addr -> {name, size, callers[], callees[]}
let mentionCache = null;  // fn_addr -> Set(source)

export function clearCaches() {
  fnCache = null;
  mentionCache = null;
  clearFreshness(); // an in-session ingest changes what "stale" means
}

/** All decompiled functions with their call-graph edges (chunk 0 carries identity). */
async function loadFns(table) {
  if (fnCache) return fnCache;
  const rows = await table.query()
    .where(`source = 'ghidra' AND chunk = 0`)
    .select(['fn_addr', 'path', 'meta'])
    .toArray();
  fnCache = new Map();
  for (const r of rows) {
    let meta = {};
    try { meta = JSON.parse(r.meta || '{}'); } catch { }
    fnCache.set(r.fn_addr, {
      name: r.path.replace('ghidra/', ''),
      size: meta.size ?? 0,
      callers: meta.callers ?? [],
      callees: meta.callees ?? [],
    });
  }
  return fnCache;
}

/** Every address mentioned outside the decompilation itself -> which sources mention it. */
async function loadMentions(table) {
  if (mentionCache) return mentionCache;
  const mentions = await table.query()
    .where(`source != 'ghidra' AND addrs != ''`)
    .select(['addrs', 'source'])
    .toArray();
  mentionCache = new Map();
  for (const r of mentions) {
    for (const a of r.addrs.split(' ')) {
      if (!a) continue;
      (mentionCache.get(a) ?? mentionCache.set(a, new Set()).get(a)).add(r.source);
    }
  }
  return mentionCache;
}

/** Which decompiled functions are / are not referenced anywhere else in the corpus. */
export async function coverage({ top = 30, sort = 'size', prefix } = {}) {
  const table = await requireTable();
  const fns = await loadFns(table);
  const mentioned = await loadMentions(table);
  let covered = 0;
  const uncovered = [];
  const coveredList = [];
  for (const [addr, f] of fns) {
    if (prefix && !addr.startsWith(normPrefix(prefix))) continue;
    const entry = { fn: f.name, addr: `0x${addr}`, size: f.size, callers: f.callers.length };
    const srcs = mentioned.get(addr);
    if (srcs) { covered++; coveredList.push({ ...entry, mentionedIn: [...srcs] }); }
    else uncovered.push(entry);
  }
  const key = sort === 'callers' ? 'callers' : 'size';
  uncovered.sort((a, b) => b[key] - a[key]);
  coveredList.sort((a, b) => b[key] - a[key]);
  const total = covered + uncovered.length;
  return {
    totalFunctions: total,
    covered,
    coveredPct: total ? Number(((covered / total) * 100).toFixed(2)) : 0,
    topUncovered: uncovered.slice(0, top),
    topCovered: coveredList.slice(0, Math.min(top, 15)),
  };
}

function normPrefix(p) {
  return p.replace(/^0x/i, '').toLowerCase();
}

/** Depth-limited BFS over the decompilation call graph, each node annotated
 *  with whether (and where) the rest of the corpus documents it. */
export async function callgraph({ ref, direction = 'both', depth = 2, maxNodes = 150 }) {
  const table = await requireTable();
  const m = String(ref).match(/([0-9a-fA-F]{5,8})\s*$/);
  if (!m) throw new Error(`could not parse an address out of '${ref}'`);
  const root = normAddr(m[1]);
  const fns = await loadFns(table);
  const mentioned = await loadMentions(table);
  if (!fns.has(root)) throw new Error(`0x${root} is not a decompiled function in the index (is the ghidra source ingested?)`);

  const node = (addr, dist) => {
    const f = fns.get(addr);
    return {
      fn: f ? f.name : `0x${addr}`,
      addr: `0x${addr}`,
      dist,
      size: f?.size ?? 0,
      callers: f?.callers.length ?? 0,
      callees: f?.callees.length ?? 0,
      documentedIn: [...(mentioned.get(addr) ?? [])],
    };
  };

  const seen = new Map([[root, node(root, 0)]]);
  const edges = [];
  let frontier = [root];
  let truncated = false;
  for (let d = 1; d <= depth && frontier.length; d++) {
    const next = [];
    for (const addr of frontier) {
      const f = fns.get(addr);
      if (!f) continue;
      const neighbors = [];
      if (direction !== 'callers') for (const c of f.callees) neighbors.push([addr, c]);
      if (direction !== 'callees') for (const c of f.callers) neighbors.push([c, addr]);
      for (const [from, to] of neighbors) {
        edges.push(`0x${from} -> 0x${to}`);
        const other = from === addr ? to : from;
        if (!seen.has(other)) {
          if (seen.size >= maxNodes) { truncated = true; continue; }
          seen.set(other, node(other, d));
          next.push(other);
        }
      }
    }
    frontier = next;
  }
  return {
    root: `0x${root}`,
    direction,
    depth,
    truncated,
    nodes: [...seen.values()].sort((a, b) => a.dist - b.dist || b.size - a.size),
    edges: [...new Set(edges)],
  };
}

export async function stats() {
  const table = await openTable();
  if (!table) return { indexed: false, hint: 'run npm run ingest in tools/corpus_mcp' };
  const rows = await table.query().select(['source', 'path']).toArray();
  const bySource = {};
  for (const r of rows) {
    const s = (bySource[r.source] ??= { chunks: 0, docs: new Set() });
    s.chunks++; s.docs.add(r.path);
  }
  return {
    indexed: true,
    totalChunks: rows.length,
    bySource: Object.fromEntries(
      Object.entries(bySource).map(([k, v]) => [k, { chunks: v.chunks, docs: v.docs.size }]),
    ),
  };
}
