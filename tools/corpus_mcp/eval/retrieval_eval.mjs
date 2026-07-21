// Labelled retrieval eval. Measures where the decisive document lands for a fixed query set,
// so a ranking change can be shown to help rather than asserted to.
//
//   node eval/retrieval_eval.mjs                  # run + print table
//   node eval/retrieval_eval.mjs --k 10           # deeper cut
//   node eval/retrieval_eval.mjs --save baseline  # write eval/results/baseline.json
//   node eval/retrieval_eval.mjs --against baseline
//
// A case is a HIT if any `expect` substring matches a result path within top-k; its rank is the
// 1-based position of the first such result. The `decision` class is the one that matters: those
// are queries phrased the way the question actually arrives, and they are what the ranking work
// is supposed to fix. The `incident` class is the regression guard — it already scores well and
// must not get worse.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { search } from '../src/search.js';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const RESULTS_DIR = path.join(HERE, 'results');

function arg(name, dflt = null) {
  const i = process.argv.indexOf(`--${name}`);
  return i >= 0 && process.argv[i + 1] && !process.argv[i + 1].startsWith('--')
    ? process.argv[i + 1]
    : (i >= 0 ? true : dflt);
}

const K = Number(arg('k', 10));
const SAVE = arg('save');
const AGAINST = arg('against');

const { cases } = JSON.parse(fs.readFileSync(path.join(HERE, 'queries.json'), 'utf8'));

/** Rank (1-based) of the first result whose path matches any expected substring; 0 = miss. */
function rankOf(results, expect) {
  for (let i = 0; i < results.length; i++) {
    const p = (results[i].path || '').toLowerCase();
    if (expect.some((e) => p.includes(e.toLowerCase()))) return i + 1;
  }
  return 0;
}

const rows = [];
for (const c of cases) {
  let results = [];
  let error = null;
  try {
    results = await search({ query: c.query, k: K });
  } catch (e) {
    error = e.message;
  }
  const rank = error ? 0 : rankOf(results, c.expect);
  rows.push({
    id: c.id,
    class: c.class,
    rank,
    error,
    top: results[0] ? `${results[0].source}:${results[0].path}` : '-',
    // what actually won, when the expected doc lost — this is the diagnostic that tells you
    // WHY a decision query misses (usually: a transcript outranked the spec)
    topSources: results.slice(0, 3).map((r) => r.source).join(','),
  });
}

const byClass = (cls) => rows.filter((r) => r.class === cls);
function summarise(rs) {
  const hits = rs.filter((r) => r.rank > 0);
  const mrr = rs.reduce((a, r) => a + (r.rank ? 1 / r.rank : 0), 0) / (rs.length || 1);
  return {
    n: rs.length,
    hit1: rs.filter((r) => r.rank === 1).length,
    hit3: rs.filter((r) => r.rank > 0 && r.rank <= 3).length,
    hits: hits.length,
    misses: rs.length - hits.length,
    mrr: Number(mrr.toFixed(4)),
  };
}

const summary = { k: K, incident: summarise(byClass('incident')), decision: summarise(byClass('decision')) };

const W = Math.max(...rows.map((r) => r.id.length));
console.log(`\nretrieval eval  (k=${K})\n`);
console.log(`${'case'.padEnd(W)}  cls       rank  top-3 sources   winner`);
console.log('-'.repeat(W + 58));
for (const r of rows) {
  const rank = r.error ? 'ERR' : (r.rank || 'MISS');
  console.log(
    `${r.id.padEnd(W)}  ${r.class.padEnd(8)}  ${String(rank).padStart(4)}  ${r.topSources.padEnd(14)}  ${r.top.slice(0, 60)}`,
  );
}
for (const [cls, s] of Object.entries(summary)) {
  if (cls === 'k') continue;
  console.log(
    `\n${cls.padEnd(9)} n=${s.n}  hit@1=${s.hit1}  hit@3=${s.hit3}  hits=${s.hits}  misses=${s.misses}  MRR=${s.mrr}`,
  );
}

if (AGAINST) {
  const prev = JSON.parse(fs.readFileSync(path.join(RESULTS_DIR, `${AGAINST}.json`), 'utf8'));
  const prevRank = Object.fromEntries(prev.rows.map((r) => [r.id, r.rank]));
  console.log(`\nvs ${AGAINST}:`);
  let better = 0, worse = 0;
  for (const r of rows) {
    const b = prevRank[r.id];
    if (b === undefined || b === r.rank) continue;
    // 0 = miss, so treat it as worse than any real rank
    const score = (x) => (x === 0 ? Infinity : x);
    const dir = score(r.rank) < score(b) ? 'BETTER' : 'WORSE ';
    if (dir === 'BETTER') better++; else worse++;
    console.log(`  ${dir} ${r.id.padEnd(W)} ${b || 'MISS'} -> ${r.rank || 'MISS'}`);
  }
  console.log(`  ${better} better, ${worse} worse`);
  if (worse > 0) process.exitCode = 1; // a regression should fail a run, not just print
}

if (SAVE) {
  fs.mkdirSync(RESULTS_DIR, { recursive: true });
  const out = path.join(RESULTS_DIR, `${SAVE === true ? 'baseline' : SAVE}.json`);
  fs.writeFileSync(out, JSON.stringify({ summary, rows }, null, 2));
  console.log(`\nwrote ${out}`);
}
