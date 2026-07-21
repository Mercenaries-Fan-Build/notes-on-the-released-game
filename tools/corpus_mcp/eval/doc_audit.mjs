// Pass 1 of the documentation cull: inventory + grade, mechanically.
//
// The target class is NOT "old docs". It is `docs/aset_format.md`: a document that states a field
// decode, marks itself **Verified: Yes**, and is wrong — and therefore outranks nothing, gets
// believed, and costs a session. Age is a weak signal; CONFIDENCE WITHOUT A WITNESS is a strong one.
//
// So each doc is scored on three axes:
//   confidence  — does it assert (verified / confirmed / proven / authoritative / SOLVED)?
//   witness     — does it say HOW it knows (measured, reproduce, a command, a count, a fixture)?
//   standing    — does it declare the front-matter contract (status/evidence/verified_on)?
//
// A doc that is confident, unwitnessed and undeclared is the work queue, highest first. That is a
// prioritisation, not a verdict: Pass 4 (adversarial blind re-read) decides truth. This pass only
// says where to look.
//
//   node eval/doc_audit.mjs                 # summary + top of the queue
//   node eval/doc_audit.mjs --top 40
//   node eval/doc_audit.mjs --csv out.csv   # full worklist

import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT, MEMORY_DIR } from '../src/config.js';
import { knowledgeMeta, splitFrontMatter } from '../src/knowledge.js';

const arg = (n, d = null) => {
  const i = process.argv.indexOf(`--${n}`);
  return i >= 0 && process.argv[i + 1] && !process.argv[i + 1].startsWith('--') ? process.argv[i + 1] : (i >= 0 ? true : d);
};
const TOP = Number(arg('top', 25));
const CSV = arg('csv');

const CONFIDENT = /\b(verified|confirmed|proven|definitive|authoritative|solved|ground truth|exact|byte-identical)\b/gi;
const HEDGED = /\b(probably|likely|assume[ds]?|guess|unverified|speculat\w+|suspect|unclear|unknown|TODO|OPEN)\b/gi;
// "How do we know?" — a command to re-run, a measured count, a fixture, an address, a test.
const WITNESS = /\b(measured|reproduce|re-run|cargo run|npm run|python |golden|oracle|fixture|test|FUN_[0-9a-f]{8}|0x[0-9a-f]{6,8}|\d{1,3}(,\d{3})+ rows|\d+\s*\/\s*\d+)\b/gi;

function* walk(dir) {
  let entries = [];
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (['node_modules', '.git', 'target', '__pycache__', 'worktrees', 'external'].includes(e.name)) continue;
      yield* walk(full);
    } else if (e.name.toLowerCase().endsWith('.md')) yield full;
  }
}

const files = [
  ...walk(path.join(REPO_ROOT, 'docs')),
  ...(fs.existsSync(MEMORY_DIR) ? walk(MEMORY_DIR) : []),
];

const now = Date.now();
const rows = [];
for (const f of files) {
  let text, stat;
  try { text = fs.readFileSync(f, 'utf8'); stat = fs.statSync(f); } catch { continue; }
  const { fm } = splitFrontMatter(text);
  const km = knowledgeMeta(text) || {};
  const count = (re) => (text.match(re) || []).length;

  // Whole-document counts measure SIZE, not trustworthiness: a long, well-evidenced doc trips
  // every keyword many times. What matters is whether each individual assertion is backed WHERE
  // IT IS MADE. So score per paragraph: an assertive paragraph with no witness token in it is a
  // BARE assertion, and those are what the cull is hunting.
  const paras = text.split(/\n\s*\n/);
  let bare = 0;
  let backed = 0;
  const bareSamples = [];
  for (const p of paras) {
    const c = (p.match(CONFIDENT) || []).length;
    if (!c) continue;
    const w = (p.match(WITNESS) || []).length;
    const h = (p.match(HEDGED) || []).length;
    if (w === 0 && h === 0) {
      bare += c;
      if (bareSamples.length < 3) bareSamples.push(p.replace(/\s+/g, ' ').trim().slice(0, 110));
    } else {
      backed += c;
    }
  }

  const confidence = count(CONFIDENT);
  const witness = count(WITNESS);
  const hedged = count(HEDGED);
  const declared = !!(km.status || km.evidence || km.verified_on);
  const ageDays = Math.floor((now - stat.mtimeMs) / 86_400_000);
  // Fraction of assertions made with nothing to back them, in their own paragraph.
  const bareRatio = bare + backed > 0 ? bare / (bare + backed) : 0;

  // Rank by BARE assertions, not by how much the doc talks. Declaring the contract is the single
  // biggest discount: a doc that states its own evidence grade has already done this pass's job.
  const score =
    bare * 4
    + bareRatio * 10
    - (declared ? 40 : 0)
    + Math.min(ageDays / 60, 3);

  rows.push({
    path: path.relative(REPO_ROOT, f).replace(/\\/g, '/'),
    bytes: text.length,
    ageDays,
    confidence,
    witness,
    hedged,
    bare,
    backed,
    bareRatio: Number(bareRatio.toFixed(2)),
    bareSamples,
    declared,
    hasFm: Object.keys(fm).length > 0,
    score: Number(score.toFixed(1)),
  });
}

rows.sort((a, b) => b.score - a.score);

const n = rows.length;
const declared = rows.filter((r) => r.declared).length;
const totalBare = rows.reduce((a, r) => a + r.bare, 0);
const totalBacked = rows.reduce((a, r) => a + r.backed, 0);
const allBare = rows.filter((r) => r.bare > 0 && r.backed === 0 && r.confidence > 0).length;

// memory/ lives outside the repo, so relative paths are ugly; show them as memory/<file>
const show = (p) => (p.includes('.claude/projects') ? 'memory/' + p.split(/[\/]/).pop() : p);

console.log(`
documentation audit - ${n} markdown files (docs/ + memory/)
`);
console.log(`  declaring the front-matter contract : ${declared} (${(100 * declared / n).toFixed(1)}%)`);
console.log(`  assertions with NO witness in their own paragraph : ${totalBare} of ${totalBare + totalBacked} (${(100 * totalBare / Math.max(1, totalBare + totalBacked)).toFixed(1)}%)`);
console.log(`  docs where EVERY assertion is bare  : ${allBare}`);
console.log(`
top ${TOP} review queue - ranked by BARE assertions (not by length):
`);
const w = Math.min(58, Math.max(...rows.slice(0, TOP).map((r) => show(r.path).length)));
console.log(`${'path'.padEnd(w)}  score  bare  backed  ratio  age(d)`);
console.log('-'.repeat(w + 38));
for (const r of rows.slice(0, TOP)) {
  console.log(
    `${show(r.path).slice(0, w).padEnd(w)}  ${String(r.score).padStart(5)}  ${String(r.bare).padStart(4)}  `
    + `${String(r.backed).padStart(6)}  ${String(r.bareRatio).padStart(5)}  ${String(r.ageDays).padStart(6)}`,
  );
}
console.log('\nsample bare assertions from the top 3:');
for (const r of rows.slice(0, 3)) {
  console.log(`
  ${show(r.path)}`);
  for (const s of r.bareSamples) console.log(`    - ${s}`);
}

if (CSV) {
  const out = ['path,bytes,age_days,confidence,witness,hedged,bare,backed,bare_ratio,declared,score']
    .concat(rows.map((r) => `${r.path},${r.bytes},${r.ageDays},${r.confidence},${r.witness},${r.hedged},${r.bare},${r.backed},${r.bareRatio},${r.declared},${r.score}`));
  fs.writeFileSync(CSV === true ? 'doc_audit.csv' : CSV, out.join('\n'));
  console.log(`
wrote ${CSV === true ? 'doc_audit.csv' : CSV} (${rows.length} rows)`);
}
