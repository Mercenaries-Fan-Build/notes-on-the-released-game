import { openTable, esc } from './db.js';
import { embedQuery } from './embed.js';
import { normAddr } from './chunk.js';

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

const RESULT_COLS = ['id', 'source', 'path', 'title', 'chunk', 'text', 'fn_addr', 'meta'];

/** Hybrid (vector + BM25) search merged with reciprocal-rank fusion. */
export async function search({ query, k = 8, sources, pathPrefix }) {
  const table = await requireTable();
  const filter = sourceFilter(sources, pathPrefix);
  const fetchN = Math.max(k * 3, 20);

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
  vres.forEach((r, i) => { scores.set(r.id, (scores.get(r.id) ?? 0) + 1 / (K + i)); byId.set(r.id, r); });
  fres.forEach((r, i) => { scores.set(r.id, (scores.get(r.id) ?? 0) + 1 / (K + i)); byId.set(r.id, r); });

  return [...scores.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, k)
    .map(([id, score]) => ({ score: Number(score.toFixed(4)), ...pick(byId.get(id)) }));
}

function pick(r) {
  return {
    id: r.id, source: r.source, path: r.path, title: r.title, chunk: r.chunk,
    fn_addr: r.fn_addr || undefined, text: r.text,
  };
}

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
