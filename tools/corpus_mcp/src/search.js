import path from 'node:path';
import { openTable, esc } from './db.js';
import { embedQuery } from './embed.js';
import { normAddr } from './chunk.js';
import { sourceFreshness } from './sources.js';
import { readMeta, standingWeight, STATUS } from './knowledge.js';
import { allArtifacts, resolveInheritChain, analyzeFile } from './lua_analyzer.js';

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
  lua_api: 1.0,    // AST facts over shipped game Lua — structural, not opinion
  tool: 0.9,       // source + READMEs: real, but incidental prose
  commit: 0.9,     // terse, and the diff is the real record
  mod: 0.9,
  conversation: 0.25, // unreviewed transcript
};

const UNREVIEWED = new Set(['conversation']);

/** Hybrid (vector + BM25) search merged with authority-weighted reciprocal-rank fusion. */
export async function search({ query, k = 8, sources, pathPrefix, includeRetracted = false }) {
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
    // authority (which source) x standing (what the document says about itself)
    const w = (SOURCE_AUTHORITY[r.source] ?? 1.0) * standingWeight(readMeta(r.meta));
    scores.set(r.id, (scores.get(r.id) ?? 0) + w / (K + i));
    byId.set(r.id, r);
  };
  vres.forEach(bump);
  fres.forEach(bump);

  let ranked = [...scores.entries()].sort((a, b) => b[1] - a[1]);
  if (!includeRetracted) {
    // Retracted knowledge stays in the index on purpose - "we tried this and it was wrong" is
    // worth finding - but it must be asked for, never volunteered as an answer.
    ranked = ranked.filter(([id]) => readMeta(byId.get(id).meta).status !== STATUS.RETRACTED);
  }
  return ranked.slice(0, k)
    .map(([id, score]) => ({ score: Number(score.toFixed(4)), ...pick(byId.get(id)) }));
}

/** `mtime` is stored at ingest but was never surfaced, so no result could be dated. */
function isoDate(mtime) {
  const ms = Number(mtime);
  if (!ms) return undefined;
  return new Date(ms).toISOString().slice(0, 10);
}

function pick(r) {
  const m = readMeta(r.meta);
  return {
    id: r.id, source: r.source, path: r.path, title: r.title, chunk: r.chunk,
    date: isoDate(r.mtime),
    // standing, when the document declares any
    status: m.status || undefined,
    evidence: m.evidence || undefined,
    verified_on: m.verified_on || undefined,
    supersedes: m.supersedes || undefined,
    superseded_by: m.superseded_by || undefined,
    // Say it in the payload, not just in the source name: a reader skimming hits should not have
    // to know that `conversation` means "nobody checked this".
    unreviewed: UNREVIEWED.has(r.source) || undefined,
    // Gitignored by intent = the author has not committed to this finding yet.
    draft: m.untracked || undefined,
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
// Lua static-analysis caches. The chunk-0 artifact rows go into luaClassCache / luaDataCache
// keyed by title; the per-record rows go into luaRecordCache keyed by `${module}.${table}`.
// All three load lazily on first query, from the LanceDB corpus if the lua_api source has been
// ingested, else from a fresh filesystem walk as a fallback.
let luaClassCache = null;   // Map<name, ClassAPI>
let luaDataCache = null;    // Map<name, DataAPI> — same shape as class rows but kind:"data"
let luaRecordCache = null;  // Map<"module.table", Map<key, {fields, line, module, table}>>
const LUA_ROOTS = [
  'tools/wad_simulator/workshop_data/lua',
  'tools/wad_simulator/workshop_data/shipments',
];

export function clearCaches() {
  fnCache = null;
  mentionCache = null;
  luaClassCache = null;
  luaDataCache = null;
  luaRecordCache = null;
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

/**
 * Lazy-load the Lua artifact caches. Prefers the LanceDB corpus (fast, no filesystem touch) if
 * the lua_api source has been ingested; falls back to a fresh filesystem walk otherwise, so
 * tools/corpus_mcp works end-to-end on a brand-new checkout before the first `npm run ingest`.
 *
 * Returns {classes, data, records}:
 *   classes: Map<name, ClassAPI>      — primary (file-basename) + alias (import()-style)
 *   data:    Map<name, DataAPI>
 *   records: Map<"module.table", Map<key, record>>
 */
async function loadLua() {
  if (luaClassCache && luaDataCache && luaRecordCache) {
    return { classes: luaClassCache, data: luaDataCache, records: luaRecordCache };
  }
  luaClassCache = new Map();
  luaDataCache = new Map();
  luaRecordCache = new Map();

  const table = await openTable();
  let rows = [];
  if (table) {
    try {
      rows = await table.query()
        .where(`source = 'lua_api' AND chunk = 0`)
        .select(['path', 'title', 'meta'])
        .toArray();
    } catch { rows = []; }
  }

  if (rows.length > 0) {
    for (const r of rows) {
      let meta = {};
      try { meta = JSON.parse(r.meta || '{}'); } catch { continue; }
      if (meta.kind === 'class') {
        luaClassCache.set(r.title, meta);
      } else if (meta.kind === 'data') {
        luaDataCache.set(r.title, meta);
      } else if (meta.kind === 'data_record') {
        const key = `${meta.module}.${meta.table}`;
        if (!luaRecordCache.has(key)) luaRecordCache.set(key, new Map());
        luaRecordCache.get(key).set(meta.key, {
          module: meta.module,
          table: meta.table,
          key: meta.key,
          line: meta.line,
          fields: meta.fields || {},
        });
      }
    }
    return { classes: luaClassCache, data: luaDataCache, records: luaRecordCache };
  }

  // Filesystem fallback. Walks the Lua roots, runs the AST analyzer, builds the same maps.
  const repoRoot = process.env.CORPUS_REPO_ROOT
    ? path.resolve(process.env.CORPUS_REPO_ROOT)
    : path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([a-zA-Z]:)/, '$1')), '..', '..', '..');
  for (const rel of LUA_ROOTS) {
    const abs = path.resolve(repoRoot, rel);
    try {
      const batch = allArtifacts(abs);
      for (const [key, api] of batch) {
        if (api.kind === 'class') {
          if (!luaClassCache.has(key)) luaClassCache.set(key, api);
        } else if (api.kind === 'data') {
          if (!luaDataCache.has(key)) luaDataCache.set(key, api);
        }
        // Build per-record cache from tables facet (works for both kinds).
        for (const t of api.tables ?? []) {
          if (t.shape !== 'record_map' || !t.records?.length) continue;
          const mkey = `${key}.${t.name}`;
          if (!luaRecordCache.has(mkey)) luaRecordCache.set(mkey, new Map());
          for (const rec of t.records) {
            if (!rec.key) continue;
            luaRecordCache.get(mkey).set(rec.key, {
              module: key, table: t.name, key: rec.key, line: rec.line, fields: rec.fields || {},
            });
          }
        }
      }
    } catch (_) { /* missing root is fine */ }
  }
  return { classes: luaClassCache, data: luaDataCache, records: luaRecordCache };
}

/**
 * Resolve a Lua artifact by name. Accepts the file-basename form (lowercase) OR the
 * import()-style name as used by other scripts (`MrxTaskObjective`, `WifMissionData`). Case-
 * insensitive fallback keeps the surface forgiving.
 */
export async function luaApi({ name, resolve_chain = true } = {}) {
  if (!name) throw new Error('luaApi: `name` is required');
  const { classes, data } = await loadLua();
  // Try class caches first (both exact and lowercase), then data.
  const tryGet = (map, k) => map.get(k) ?? map.get(k.toLowerCase());
  let art = tryGet(classes, name) ?? tryGet(data, name);
  if (!art) {
    const keys = [...classes.keys(), ...data.keys()];
    const lower = name.toLowerCase();
    const near = keys.filter((k) => k.toLowerCase().includes(lower)).slice(0, 10);
    return { error: `no Lua artifact "${name}" found`, nearest: near };
  }
  if (art.kind === 'class' && resolve_chain) {
    return resolveInheritChain(art, (parent) => tryGet(classes, parent) ?? null);
  }
  return art;
}

/**
 * Cross-reference a Lua symbol. Walks every class's `imports`, `calls_on_super`,
 * `calls_on_self`, `calls_on_mission_ancestor`, `calls_on_parent`, `data_tables_read`, and
 * also inspects every data record's scalar field values. Returns the call sites + record
 * matches, grouped by source location.
 *
 *   luaXref("MrxTask.CreateChild") → every class that calls CreateChild on a MrxTask ancestor
 *   luaXref("PmcBoss")             → every record with a scalar PmcBoss AND every call site
 *   luaXref("CreateChild")         → class/method matches ignoring the module prefix
 */
export async function luaXref({ symbol, limit = 100 } = {}) {
  if (!symbol) throw new Error('luaXref: `symbol` is required');
  const { classes, data, records } = await loadLua();
  const hits = [];
  const push = (hit) => { if (hits.length < limit) hits.push(hit); };

  // Split "Module.Method" if given; otherwise match the whole thing against any name token.
  const [maybeModule, maybeMethod] = symbol.includes('.') ? symbol.split('.', 2) : [null, symbol];

  const matchSuper = (c) => (maybeModule ? c.module === maybeModule && c.method === maybeMethod : c.method === maybeMethod);
  const matchGeneric = (name) => (maybeModule === null ? name === maybeMethod : name === maybeMethod);

  for (const [className, cls] of classes) {
    for (const c of cls.calls_on_super ?? []) {
      if (matchSuper(c)) push({ in_class: className, where: 'calls_on_super', module: c.module, method: c.method, line: c.line, source_path: cls.source_path });
    }
    for (const c of cls.calls_on_self ?? []) {
      if (matchGeneric(c.method)) push({ in_class: className, where: 'calls_on_self', method: c.method, line: c.line, source_path: cls.source_path });
    }
    for (const c of cls.calls_on_mission_ancestor ?? []) {
      if (matchGeneric(c.method)) push({ in_class: className, where: 'calls_on_mission_ancestor', method: c.method, line: c.line, source_path: cls.source_path });
    }
    for (const c of cls.calls_on_parent ?? []) {
      if (matchGeneric(c.method)) push({ in_class: className, where: 'calls_on_parent', method: c.method, line: c.line, source_path: cls.source_path });
    }
    for (const d of cls.data_tables_read ?? []) {
      if (maybeModule ? (d.module === maybeModule && d.field === maybeMethod) : d.field === maybeMethod) {
        push({ in_class: className, where: 'data_tables_read', module: d.module, field: d.field, line: d.line, source_path: cls.source_path });
      }
    }
    if (cls.imports?.includes(symbol)) push({ in_class: className, where: 'imports', module: symbol, source_path: cls.source_path });
  }

  // Scan every data record's scalar field values for a match on the symbol.
  for (const [mkey, recMap] of records) {
    for (const rec of recMap.values()) {
      for (const [field, val] of Object.entries(rec.fields ?? {})) {
        if (val === symbol) push({ where: 'data_record_value', module: rec.module, table: rec.table, key: rec.key, field, value: val, line: rec.line });
      }
    }
  }

  return { symbol, hits, hitCount: hits.length, truncated: hits.length >= limit };
}

/**
 * Walk the Lua class graph outward from `root`. `direction` controls which edges are followed:
 *   - "parents"   — only inherit_chain upward
 *   - "children"  — only `calls_on_super` into this class from other classes (inverse edge)
 *   - "both"      — both directions
 *
 * Follows at most `depth` hops, bounded by `maxNodes`. Returns nodes + edges, matching the
 * shape of `callgraph()` for Ghidra fns.
 */
export async function luaCallgraph({ root, direction = 'both', depth = 2, maxNodes = 150 } = {}) {
  if (!root) throw new Error('luaCallgraph: `root` is required');
  const { classes } = await loadLua();
  const tryGet = (k) => classes.get(k) ?? classes.get(k.toLowerCase());
  const start = tryGet(root);
  if (!start) return { root, error: 'not a known class', nearest: [...classes.keys()].filter((k) => k.toLowerCase().includes(root.toLowerCase())).slice(0, 10) };

  // Pre-build the inverse "who calls me as super" edge map.
  const invSuper = new Map(); // Map<className, Set<childClassName>>
  for (const [cName, cls] of classes) {
    for (const c of cls.calls_on_super ?? []) {
      const parent = c.module.toLowerCase();
      if (!invSuper.has(parent)) invSuper.set(parent, new Set());
      invSuper.get(parent).add(cName);
    }
  }

  const seen = new Map();  // name -> {dist, methodsCount}
  const edges = [];
  const q = [{ name: start.class, art: start, dist: 0 }];
  seen.set(start.class, { dist: 0, methodsCount: (start.methods_defined ?? []).length });
  let truncated = false;
  while (q.length) {
    const { name, art, dist } = q.shift();
    if (dist >= depth) continue;
    if (seen.size >= maxNodes) { truncated = true; break; }

    if (direction === 'parents' || direction === 'both') {
      // inherit_chain[0] is self; rest are ancestors
      const parents = (art.inherit_chain ?? []).slice(1);
      for (const p of parents) {
        edges.push({ from: name, to: p, kind: 'inherits' });
        if (!seen.has(p)) {
          const parentArt = tryGet(p);
          seen.set(p, { dist: dist + 1, methodsCount: (parentArt?.methods_defined ?? []).length });
          if (parentArt) q.push({ name: p, art: parentArt, dist: dist + 1 });
        }
      }
    }
    if (direction === 'children' || direction === 'both') {
      const kids = invSuper.get(name.toLowerCase()) ?? new Set();
      for (const k of kids) {
        edges.push({ from: k, to: name, kind: 'inherits' });
        if (!seen.has(k)) {
          const kidArt = tryGet(k);
          seen.set(k, { dist: dist + 1, methodsCount: (kidArt?.methods_defined ?? []).length });
          if (kidArt) q.push({ name: k, art: kidArt, dist: dist + 1 });
        }
      }
    }
  }

  const nodes = [...seen.entries()].map(([name, meta]) => ({ name, ...meta })).sort((a, b) => a.dist - b.dist);
  return { root: start.class, direction, depth, truncated, nodes, edges };
}

/**
 * Filter a data table's records by a scalar field predicate.
 *
 *   luaRecords({module: "WifMissionData", table: "tMissionData", where: {sStarter: "PmcBoss"}})
 *   → every mission whose sStarter is literally the string "PmcBoss".
 *
 * `where` is a flat object of {field: value}; all must match. Supports string / number / boolean
 * equality only. Nested-table fields (preview "<nested table>") are not filterable.
 */
export async function luaRecords({ module, table: tableName, where = {} } = {}) {
  if (!module || !tableName) throw new Error('luaRecords: `module` and `table` are required');
  const { records, data, classes } = await loadLua();
  // The record cache keys combine the resolver-normalized module name + table name. The caller
  // may pass either the file-basename ("wifmissiondata") or the import()-style name
  // ("WifMissionData"); the record cache key uses whatever the artifact's own `title` was,
  // which is file-basename.
  const tryKeys = [
    `${module}.${tableName}`,
    `${module.toLowerCase()}.${tableName}`,
  ];
  let bucket = null;
  for (const k of tryKeys) {
    if (records.has(k)) { bucket = records.get(k); break; }
  }
  if (!bucket) {
    return { module, table: tableName, error: 'no such data table in index', hint: 'try `corpus_lua_api <module>` first to see available tables' };
  }

  const whereEntries = Object.entries(where);
  const matches = [];
  for (const rec of bucket.values()) {
    let ok = true;
    for (const [field, want] of whereEntries) {
      if (rec.fields?.[field] !== want) { ok = false; break; }
    }
    if (ok) matches.push({ key: rec.key, line: rec.line, fields: rec.fields });
  }
  return { module, table: tableName, where, matches, matchCount: matches.length, totalInTable: bucket.size };
}
