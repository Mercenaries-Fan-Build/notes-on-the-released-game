// Knowledge metadata: the front-matter contract that lets one finding OVERTURN another.
//
// The corpus had no way to say "this was superseded". `docs/aset_format.md` marks a field decode
// "Verified: **Yes**" and is contradicted by a later whole-WAD measurement; `model-lod-block-chain`
// asserts "Characters ship ONE block" and is wrong for 47 of 85 characters. Both still rank as
// confident current knowledge, because ranking sees text and dates, never *standing*.
//
// So a document may declare:
//
//   ---
//   status: current | superseded | retracted
//   supersedes: [docs/old_thing.md]      # or a single path, or a block list
//   evidence: proven | inferred | speculative
//   verified_on: 2026-07-21
//   witness: whole-WAD ASET partition; civ_hum_beachfemale_a resolves to block 4587
//   ---
//
// Nothing is mandatory — an undeclared doc keeps today's behaviour exactly. The point is that a
// correction can now outrank the thing it corrects, instead of sitting beside it forever.

/** Statuses that change how a hit is ranked or shown. */
export const STATUS = { CURRENT: 'current', SUPERSEDED: 'superseded', RETRACTED: 'retracted' };
export const EVIDENCE = ['proven', 'inferred', 'speculative'];

/**
 * Ranking multiplier for a document's standing.
 * `retracted` is not zero: it stays reachable on request, because in a reverse-engineering project
 * a wrong turn is itself evidence — you want to find out that you already tried this and it failed.
 */
export const STATUS_WEIGHT = {
  [STATUS.CURRENT]: 1.0,
  [STATUS.SUPERSEDED]: 0.35,
  [STATUS.RETRACTED]: 0.15,
};

/** Evidence grade nudges ranking: a proven claim should beat a guess that phrases itself better. */
export const EVIDENCE_WEIGHT = { proven: 1.0, inferred: 0.92, speculative: 0.8 };

const SCALAR_KEYS = ['status', 'evidence', 'verified_on', 'witness', 'name', 'description'];
const LIST_KEYS = ['supersedes', 'superseded_by'];

/**
 * Split leading `---` front-matter from the body. Deliberately a tiny YAML subset (scalars, inline
 * `[a, b]` lists, `- item` block lists, one level of nesting) rather than a YAML dependency: the
 * contract above is all we parse, and an unparseable field must degrade to "not declared", never
 * throw during ingest.
 */
export function splitFrontMatter(text) {
  if (!text.startsWith('---')) return { fm: {}, body: text };
  const end = text.indexOf('\n---', 3);
  if (end < 0) return { fm: {}, body: text };
  // `end` points at the '\n' that TERMINATES the last key line. On a CRLF file that line's own
  // '\r' sits at end-1, so slicing to `end` leaves a trailing '\r' on the final key and the
  // key regex rejects it — silently dropping exactly one field, always the last one. Measured:
  // `---\r\nstatus: current\r\nevidence: proven\r\n---` parsed as {status} with no evidence.
  // Most files in this repo are CRLF, so this quietly ate a field from nearly every doc graded.
  const raw = text.slice(3, end).replace(/\r$/, '');
  const body = text.slice(text.indexOf('\n', end + 1) + 1);
  return { fm: parseYamlLite(raw), body };
}

function parseYamlLite(raw) {
  const out = {};
  let listKey = null;
  let blockKey = null;   // `witness: |` — collect the indented body, don't store the '|'
  let blockFold = false; // '>' folds newlines into spaces; '|' keeps them
  let blockLines = [];

  const flushBlock = () => {
    if (blockKey) out[blockKey] = blockLines.join(blockFold ? ' ' : '\n').trim();
    blockKey = null;
    blockLines = [];
  };

  for (const line of raw.split(/\r?\n/)) {
    // A block scalar swallows every MORE-indented line, including blanks and '#' — those are
    // content, not comments, so this has to run before the skip rules below.
    if (blockKey !== null) {
      if (!line.trim() || /^\s/.test(line)) { blockLines.push(line.trim()); continue; }
      flushBlock();
    }
    if (!line.trim() || line.trim().startsWith('#')) continue;
    const item = line.match(/^\s*-\s+(.*)$/);
    if (item && listKey) { (out[listKey] ??= []).push(strip(item[1])); continue; }
    const kv = line.match(/^(\s*)([A-Za-z_][\w-]*)\s*:\s*(.*)$/);
    if (!kv) continue;
    const [, indent, key, rest] = kv;
    if (indent.length > 0) continue; // nested (e.g. metadata.type) — not part of the contract
    const val = rest.trim();
    // Block scalar: `witness: |` / `>` (with optional chomp indicator). Storing the bare '|' as
    // the value — which is what a naive parse does — is worse than storing nothing, because
    // `witness` is the field that says HOW we know.
    if (/^[|>][-+]?$/.test(val)) {
      listKey = null;
      blockKey = key;
      blockFold = val.startsWith('>');
      blockLines = [];
      continue;
    }
    if (val === '') { listKey = key; continue; }
    listKey = null;
    if (val.startsWith('[')) {
      out[key] = val.replace(/^\[|\]$/g, '').split(',').map(strip).filter(Boolean);
    } else {
      out[key] = strip(val);
    }
  }
  flushBlock();
  return out;
}

const strip = (s) => String(s).trim().replace(/^["']|["']$/g, '');

/**
 * Extract just the contract fields into a compact object suitable for the `meta` column.
 * Returns `null` when a document declares nothing, so ingest stores '' and nothing changes.
 */
export function knowledgeMeta(text) {
  const { fm } = splitFrontMatter(text);
  const meta = {};
  for (const k of SCALAR_KEYS) {
    if (k === 'name' || k === 'description') continue; // display-only; not ranking signals
    if (fm[k]) meta[k] = String(fm[k]).toLowerCase() === fm[k] ? fm[k] : fm[k];
  }
  for (const k of LIST_KEYS) {
    if (!fm[k]) continue;
    meta[k] = Array.isArray(fm[k]) ? fm[k] : [fm[k]];
  }
  if (meta.status && !Object.values(STATUS).includes(String(meta.status).toLowerCase())) delete meta.status;
  if (meta.evidence && !EVIDENCE.includes(String(meta.evidence).toLowerCase())) delete meta.evidence;
  return Object.keys(meta).length ? meta : null;
}

/** Parse a stored `meta` cell back into an object (ghidra rows store their own shape). */
export function readMeta(cell) {
  if (!cell) return {};
  try { const o = JSON.parse(cell); return o && typeof o === 'object' ? o : {}; } catch { return {}; }
}

/**
 * Weight for a doc the repo does not track.
 *
 * Gitignored drafts are deliberate: the author does not want unconfirmed or unfinished findings
 * committed. But the corpus indexes the filesystem, so those drafts were ranking beside verified
 * research with nothing to distinguish them. Untracked == "not committed to" in both senses, which
 * is a real standing signal — so demote, but only moderately: a draft is often the NEWEST thinking
 * and should still outrank an unreviewed transcript (0.25). It is a draft, not a wrong answer.
 */
export const UNTRACKED_WEIGHT = 0.55;

/** Combined standing multiplier for a row's meta. */
export function standingWeight(meta) {
  const status = String(meta.status ?? STATUS.CURRENT).toLowerCase();
  const evidence = String(meta.evidence ?? 'proven').toLowerCase();
  // An explicit declaration beats an inference: a draft that states `status: current,
  // evidence: proven` has said something the file's git state cannot say for it.
  const untracked = meta.untracked && !meta.status && !meta.evidence ? UNTRACKED_WEIGHT : 1.0;
  return (STATUS_WEIGHT[status] ?? 1.0) * (EVIDENCE_WEIGHT[evidence] ?? 1.0) * untracked;
}
