import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import { execFileSync } from 'node:child_process';
import {
  REPO_ROOT, SOURCES, MEMORY_DIR, TRANSCRIPTS_DIR, GHIDRA_EXPORTS, GHIDRA_IMAGES,
  MAX_FILE_BYTES, CONVO_WINDOW,
} from './config.js';
import { chunkMarkdown, chunkText, chunkCode, sha256, extractAddrs } from './chunk.js';
import { knowledgeMeta } from './knowledge.js';
import { analyzeFile as luaAnalyzeFile } from './lua_analyzer.js';

/** A document = one ingestion unit:
 *  { source, path, title, mtime, fileHash, chunks: [text], meta?, imageId?, imageSha256?, va?, images? }
 *  (the image fields are set by ghidraDocs only). */

function rel(p) {
  return path.relative(REPO_ROOT, p).replace(/\\/g, '/');
}

function* walk(dir, excludeDirs = []) {
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      const r = rel(full);
      if (e.name === 'node_modules' || e.name === '__pycache__' || e.name === '.git') continue;
      if (excludeDirs.some((x) => r.endsWith('/' + x) || r.includes('/' + x + '/') || e.name === x)) continue;
      yield* walk(full, excludeDirs);
    } else if (e.isFile()) {
      yield full;
    }
  }
}

/**
 * Stat-only sweep of the file-backed sources: newest on-disk mtime and how many files are newer
 * than a given cutoff. Deliberately does NOT read or hash anything, so it is cheap enough to run
 * behind a search; `fileDocs` reads every file, which is not.
 *
 * This exists because the index has no way to announce that it is out of date. A stale corpus
 * answers confidently with yesterday's knowledge, which is indistinguishable from a correct
 * answer at the moment you need it most.
 */
export function sourceFreshness(cutoffByName = {}) {
  const out = {};
  for (const [name, spec] of Object.entries(SOURCES)) {
    // memory/conversations/commits/ghidra are `special` walkers; handle the two that are cheap
    // and file-backed, and report the rest as unknown rather than guessing.
    let files = [];
    if (spec.dirs) {
      for (const d of spec.dirs) {
        for (const f of walk(path.join(REPO_ROOT, d), spec.excludeDirs || [])) {
          if (!spec.exts || spec.exts.includes(path.extname(f).toLowerCase())) files.push(f);
        }
      }
      for (const extra of spec.extraFiles || []) {
        const f = path.join(REPO_ROOT, extra);
        if (fs.existsSync(f)) files.push(f);
      }
    } else if (spec.special === 'memory') {
      try {
        files = fs.readdirSync(MEMORY_DIR).filter((n) => n.endsWith('.md')).map((n) => path.join(MEMORY_DIR, n));
      } catch { files = []; }
    } else if (spec.special === 'lua_api') {
      // Walk the Lua corpus roots the generator consumes. Keeps freshness honest even though
      // the generator itself runs the AST analyzer — the stat sweep only cares about mtime.
      for (const relRoot of ['tools/wad_simulator/workshop_data/lua', 'tools/wad_simulator/workshop_data/shipments']) {
        const abs = path.join(REPO_ROOT, relRoot);
        if (!fs.existsSync(abs)) continue;
        for (const f of walk(abs)) if (f.endsWith('.lua')) files.push(f);
      }
    } else {
      out[name] = { known: false };
      continue;
    }
    const cutoff = cutoffByName[name] ?? 0;
    let newest = 0;
    const newer = [];
    for (const f of files) {
      let st;
      try { st = fs.statSync(f); } catch { continue; }
      if (st.mtimeMs > newest) newest = st.mtimeMs;
      if (st.mtimeMs > cutoff + 1000) newer.push(rel(f)); // 1s slack for fs/index timestamp skew
    }
    out[name] = { known: true, files: files.length, newest, newerThanIndex: newer.length, examples: newer.slice(0, 5) };
  }
  return out;
}

/**
 * Paths git tracks, as repo-relative forward-slash strings.
 *
 * This is a PROVENANCE signal, not a bug to fix. Drafts are gitignored on purpose — the repo
 * should not carry findings that are unconfirmed or unfinished (`.gitignore` excludes
 * `*investigation*.md` and `docs/**plan*.md`). But the corpus walks the FILESYSTEM, so it indexed
 * those drafts alongside committed research and search could not tell them apart: an unreviewed
 * working note ranked exactly like a verified spec.
 *
 * So use the author's own signal. Untracked-but-indexed == "the author has not committed to this",
 * which is precisely the standing the ranker should reflect. One `git ls-files` beats 400
 * `git check-ignore` calls.
 */
let trackedCache = null;
function trackedPaths() {
  if (trackedCache) return trackedCache;
  trackedCache = new Set();
  try {
    const out = execFileSync('git', ['ls-files'], { cwd: REPO_ROOT, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
    for (const line of out.split('\n')) if (line.trim()) trackedCache.add(line.trim());
  } catch { /* not a git tree — treat everything as tracked rather than flag the whole corpus */ }
  return trackedCache;
}

/** Reset between test runs / after a checkout. */
export function clearTrackedCache() { trackedCache = null; }

function chunksFor(file, text) {
  const ext = path.extname(file).toLowerCase();
  if (ext === '.md') return chunkMarkdown(text);
  if (['.py', '.rs', '.c', '.h', '.cpp', '.lua', '.sh', '.toml', '.def', '.mk'].includes(ext) || path.basename(file) === 'Makefile')
    return chunkCode(text);
  return chunkText(text);
}

/** Generic file-tree source (doc / mod / tool / project). */
export function* fileDocs(sourceName) {
  const spec = SOURCES[sourceName];
  const files = new Set();
  for (const d of spec.dirs || []) {
    for (const f of walk(path.join(REPO_ROOT, d), spec.excludeDirs || [])) {
      if (spec.exts.includes(path.extname(f).toLowerCase())) files.add(f);
    }
  }
  for (const extra of spec.extraFiles || []) {
    const f = path.join(REPO_ROOT, extra);
    if (fs.existsSync(f)) files.add(f);
  }
  for (const file of files) {
    let stat;
    try { stat = fs.statSync(file); } catch { continue; }
    if (stat.size > MAX_FILE_BYTES || stat.size === 0) continue;
    const text = fs.readFileSync(file, 'utf8');
    // Front-matter standing (status/supersedes/evidence) rides in `meta`, so a corrected doc can
    // outrank the one it corrects. Only markdown declares it; everything else stores nothing.
    const km = path.extname(file).toLowerCase() === '.md' ? knowledgeMeta(text) : null;
    // A file inside the repo that git does not track is a DRAFT by the author's own convention
    // (see `trackedPaths`). Record it so ranking can treat it as unconfirmed; a doc that declares
    // its own `status` still wins, because an explicit declaration beats an inference.
    const p = rel(file);
    const meta = { ...(km || {}) };
    if (!trackedPaths().has(p)) meta.untracked = true;
    yield {
      source: sourceName,
      path: p,
      title: p,
      mtime: stat.mtimeMs,
      fileHash: sha256(text),
      chunks: chunksFor(file, text),
      meta: Object.keys(meta).length ? JSON.stringify(meta) : undefined,
    };
  }
}

/** Persistent memory files. */
export function* memoryDocs() {
  if (!fs.existsSync(MEMORY_DIR)) return;
  for (const name of fs.readdirSync(MEMORY_DIR)) {
    if (!name.endsWith('.md')) continue;
    const file = path.join(MEMORY_DIR, name);
    const stat = fs.statSync(file);
    const text = fs.readFileSync(file, 'utf8');
    yield {
      source: 'memory',
      path: `memory/${name}`,
      title: `memory/${name}`,
      mtime: stat.mtimeMs,
      fileHash: sha256(text),
      chunks: chunkMarkdown(text),
      meta: (() => { const km = knowledgeMeta(text); return km ? JSON.stringify(km) : undefined; })(),
    };
  }
}

const SKIP_TEXT_PREFIXES = [
  'Caveat: The messages below',
  '<command-name>', '<local-command', '<bash-input>', '<bash-stdout',
  '<system-reminder', "API Error", "[Request interrupted",
];

function usableText(t) {
  if (!t || t.length < 8) return null;
  const s = t.trim();
  for (const p of SKIP_TEXT_PREFIXES) if (s.startsWith(p)) return null;
  // Strip embedded system-reminder blocks from otherwise-real messages.
  return s.replace(/<system-reminder>[\s\S]*?<\/system-reminder>/g, '').trim() || null;
}

/** One conversation jsonl -> windows of "[user]/[claude] text" turns. */
async function conversationDoc(file) {
  const stat = fs.statSync(file);
  const turns = [];
  let firstUser = null;
  const rl = readline.createInterface({
    input: fs.createReadStream(file, 'utf8'),
    crlfDelay: Infinity,
  });
  for await (const line of rl) {
    let e;
    try { e = JSON.parse(line); } catch { continue; }
    if (e.type === 'summary' && typeof e.summary === 'string') {
      turns.push(`[summary] ${e.summary}`);
      continue;
    }
    if (e.type !== 'user' && e.type !== 'assistant') continue;
    const content = e.message?.content;
    const role = e.type === 'user' ? 'user' : 'claude';
    const tag = e.isSidechain ? `${role}:sub` : role;
    const texts = [];
    if (typeof content === 'string') texts.push(content);
    else if (Array.isArray(content)) {
      for (const item of content) if (item.type === 'text' && item.text) texts.push(item.text);
    }
    for (const t of texts) {
      const u = usableText(t);
      if (!u) continue;
      if (!firstUser && e.type === 'user' && !e.isSidechain) firstUser = u.slice(0, 120);
      turns.push(`[${tag}] ${u}`);
    }
  }
  // Window consecutive turns into chunks.
  const chunks = [];
  let cur = '';
  for (const t of turns) {
    if (cur.length + t.length + 1 > CONVO_WINDOW && cur) {
      chunks.push(cur);
      cur = '';
    }
    // Hard-split single giant turns.
    for (const piece of t.length > CONVO_WINDOW * 1.5 ? chunkText(t, CONVO_WINDOW, 100) : [t]) {
      if (cur.length + piece.length + 1 > CONVO_WINDOW && cur) { chunks.push(cur); cur = ''; }
      cur = cur ? cur + '\n' + piece : piece;
    }
  }
  if (cur) chunks.push(cur);
  const session = path.basename(file, '.jsonl');
  return {
    source: 'conversation',
    path: `conversations/${session}.jsonl`,
    title: firstUser ? `session ${session.slice(0, 8)}: ${firstUser}` : `session ${session.slice(0, 8)}`,
    mtime: stat.mtimeMs,
    // Cheap identity: size+mtime (hashing 100MB files each run is wasteful).
    fileHash: sha256(`${stat.size}:${stat.mtimeMs}`),
    chunks,
  };
}

export async function* conversationDocs() {
  if (!fs.existsSync(TRANSCRIPTS_DIR)) return;
  for (const name of fs.readdirSync(TRANSCRIPTS_DIR)) {
    if (!name.endsWith('.jsonl')) continue;
    yield await conversationDoc(path.join(TRANSCRIPTS_DIR, name));
  }
}

/** Git commit messages, all branches; one doc per commit. */
export function* commitDocs() {
  let raw;
  try {
    raw = execFileSync(
      'git',
      ['log', '--all', '--date=iso-strict', '--pretty=format:%H%x1f%ad%x1f%an%x1f%B%x1e'],
      { cwd: REPO_ROOT, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 },
    );
  } catch {
    return;
  }
  for (const rec of raw.split('\x1e')) {
    const [sha, date, author, body] = rec.trim().split('\x1f');
    if (!sha || !body?.trim()) continue;
    yield {
      source: 'commit',
      path: `commit/${sha.slice(0, 12)}`,
      title: body.split('\n')[0].slice(0, 120),
      mtime: Date.parse(date) || 0,
      fileHash: sha256(sha + body),
      chunks: [`commit ${sha.slice(0, 12)} (${date}, ${author})\n${body.trim()}`],
    };
  }
}

// ---------------------------------------------------------------------------------------------
// Ghidra: one doc per (image, function VA), from two JSON Lines files per image in GHIDRA_EXPORTS:
//   <image_id>.functions.jsonl  — the Ghidra exporter: image record, one record per function, end
//   <image_id>.annotate.jsonl   — `exemap annotate`: image record, names + translations per
//                                 function in the same order, end
// The image set is GHIDRA_IMAGES (images.tsv). An image with a `code_image` shares that image's
// code: it has no files of its own and must be listed in its code image's annotate `variants`.
// A code image with neither file is not exported yet: it is not indexed, and the plan lists it
// (with its variants) so ingest and corpus_status report it. Every other check below is a hard
// failure naming the file (and line) — a partial or mismatched export must never be indexed as if
// it were whole.

const VA_RE = /^0x[0-9a-f]{8}$/;
const SHA256_RE = /^[0-9a-f]{64}$/;
/** callee tokens (FnMnemonicSig.java's call-list grammar, parsed by mercs2_exemap `Callee::parse`):
 *  a direct VA, an import, an indirect call through a memory slot / a stack variable at a signed
 *  frame offset (`*stack:0x10`, `*stack:-0x68`), an unresolved target, a syscall. */
const CALLEE_RE = /^(?:0x[0-9a-f]{8}|ext:[^!]+!.+|\*0x[0-9a-f]+|\*stack:-?0x[0-9a-f]+|\?|sys:\d+)$/;
const EXT_RE = /^ext:[^!]+!.+$/;

const FN_IMAGE_KEYS = ['kind', 'image_id', 'program', 'program_sha256', 'ghidra_version', 'language', 'compiler_spec', 'functions'];
const FN_KEYS = ['kind', 'va', 'name', 'name_source', 'block', 'size', 'thunk', 'thunk_target', 'callers', 'callees', 'decomp', 'decomp_error'];
const FN_END_KEYS = ['kind', 'functions', 'decompiled', 'failed'];
const ANN_IMAGE_KEYS = ['kind', 'image_id', 'sha256', 'variants', 'graph_images', 'untranslatable_images'];
const ANN_KEYS = ['va', 'names', 'translations'];
const ANN_END_KEYS = ['kind', 'functions'];

function fail(file, line, msg) {
  throw new Error(`[ghidra] ${file}${line ? `:${line}` : ''}: ${msg}`);
}

/** Exact key set: an unknown field is a producer change this reader does not handle yet. */
function requireKeys(obj, keys, file, line, what) {
  if (!obj || typeof obj !== 'object' || Array.isArray(obj)) fail(file, line, `${what} is not a JSON object`);
  const have = Object.keys(obj);
  const missing = keys.filter((k) => !have.includes(k));
  const extra = have.filter((k) => !keys.includes(k));
  if (missing.length || extra.length) {
    fail(file, line, `${what} keys differ from the export contract (missing: ${missing.join(', ') || 'none'}; unknown: ${extra.join(', ') || 'none'})`);
  }
}

const isCount = (n) => Number.isInteger(n) && n >= 0;

/** Parse images.tsv into Map<image_id, {id, sha256, language, codeImage|null, line}>. */
export function readImagesTsv(file) {
  if (!fs.existsSync(file)) fail(file, 0, 'images table not found');
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  if (lines[lines.length - 1] === '') lines.pop(); // the file's trailing newline
  if (!lines.length) fail(file, 0, 'images table is empty');
  const header = lines[0].split('\t');
  const col = (name) => {
    const i = header.indexOf(name);
    if (i < 0) fail(file, 1, `header has no '${name}' column`);
    return i;
  };
  const iId = col('image_id'), iSha = col('sha256'), iLang = col('ghidra_language'), iCode = col('code_image');
  const images = new Map();
  for (let n = 2; n <= lines.length; n++) {
    const f = lines[n - 1].split('\t');
    if (f.length !== header.length) fail(file, n, `${f.length} fields, header has ${header.length}`);
    const id = f[iId];
    if (!id || id === '-') fail(file, n, 'image_id holds no value');
    if (images.has(id)) fail(file, n, `image_id ${id} repeats line ${images.get(id).line}`);
    if (!SHA256_RE.test(f[iSha])) fail(file, n, `sha256 '${f[iSha]}' is not 64 lowercase hex digits`);
    if (!f[iLang] || f[iLang] === '-') fail(file, n, 'ghidra_language holds no value');
    if (!f[iCode]) fail(file, n, "code_image is empty (no value is written '-')");
    images.set(id, { id, sha256: f[iSha], language: f[iLang], codeImage: f[iCode] === '-' ? null : f[iCode], line: n });
  }
  if (!images.size) fail(file, 0, 'images table has no rows');
  for (const img of images.values()) {
    if (!img.codeImage) continue;
    const code = images.get(img.codeImage);
    if (!code) fail(file, img.line, `code_image ${img.codeImage} is not an image in this table`);
    if (code.codeImage) fail(file, img.line, `code_image ${img.codeImage} itself names code_image ${code.codeImage}`);
  }
  return images;
}

/** JSON Lines reader: yields {n, obj}; a blank or unparseable line is a hard failure. */
async function* jsonLines(file) {
  const input = fs.createReadStream(file, 'utf8');
  const rl = readline.createInterface({ input, crlfDelay: Infinity });
  let n = 0;
  try {
    for await (const line of rl) {
      n++;
      if (!line) fail(file, n, 'blank line');
      let obj;
      try { obj = JSON.parse(line); } catch (e) { fail(file, n, `not JSON: ${e.message}`); }
      yield { n, obj };
    }
  } finally {
    rl.close();
    input.destroy();
  }
}

function checkImageList(list, images, file, line, what) {
  if (!Array.isArray(list) || list.some((x) => typeof x !== 'string')) fail(file, line, `${what} is not an array of image ids`);
  for (const id of list) if (!images.has(id)) fail(file, line, `${what} names '${id}', which is not in images.tsv`);
}

function checkFunction(o, file, n) {
  requireKeys(o, FN_KEYS, file, n, 'function record');
  if (o.kind !== 'function') fail(file, n, `kind '${o.kind}' where a function record (or the end record) belongs`);
  if (!VA_RE.test(o.va)) fail(file, n, `va '${o.va}' is not 0x + 8 lowercase hex digits`);
  if (typeof o.name !== 'string' || !o.name) fail(file, n, 'name is not a non-empty string');
  if (typeof o.name_source !== 'string' || !o.name_source) fail(file, n, 'name_source is not a non-empty string');
  if (typeof o.block !== 'string' || !o.block) fail(file, n, 'block is not a non-empty string');
  if (!isCount(o.size)) fail(file, n, `size ${JSON.stringify(o.size)} is not a non-negative integer`);
  if (typeof o.thunk !== 'boolean') fail(file, n, 'thunk is not a boolean');
  // A thunk's target is its in-image function's va, or an import named as in the call list.
  if (o.thunk_target !== null && !VA_RE.test(o.thunk_target) && !EXT_RE.test(o.thunk_target)) {
    fail(file, n, `thunk_target '${o.thunk_target}' is neither null, a va, nor ext:<library>!<name>`);
  }
  if (!o.thunk && o.thunk_target !== null) fail(file, n, 'thunk_target is set on a function that is not a thunk');
  if (!Array.isArray(o.callers)) fail(file, n, 'callers is not an array');
  for (const c of o.callers) {
    requireKeys(c, ['site', 'function'], file, n, 'caller');
    if (!VA_RE.test(c.site)) fail(file, n, `caller site '${c.site}' is not a va`);
    if (c.function !== null && !VA_RE.test(c.function)) fail(file, n, `caller function '${c.function}' is neither null nor a va`);
  }
  if (!Array.isArray(o.callees)) fail(file, n, 'callees is not an array');
  for (const c of o.callees) if (typeof c !== 'string' || !CALLEE_RE.test(c)) fail(file, n, `callee ${JSON.stringify(c)} is not a known callee token`);
  if (o.decomp !== null && typeof o.decomp !== 'string') fail(file, n, 'decomp is neither a string nor null');
  if (o.decomp_error !== null && typeof o.decomp_error !== 'string') fail(file, n, 'decomp_error is neither a string nor null');
  if ((o.decomp === null) === (o.decomp_error === null)) fail(file, n, 'exactly one of decomp / decomp_error must be set');
}

function checkAnnotation(o, images, file, n) {
  requireKeys(o, ANN_KEYS, file, n, 'annotation record');
  if (!VA_RE.test(o.va)) fail(file, n, `va '${o.va}' is not 0x + 8 lowercase hex digits`);
  if (!Array.isArray(o.names)) fail(file, n, 'names is not an array');
  for (const x of o.names) {
    requireKeys(x, ['name', 'source', 'detail'], file, n, 'name entry');
    if (typeof x.name !== 'string' || !x.name) fail(file, n, 'name entry has no name');
    if (typeof x.source !== 'string' || !x.source) fail(file, n, `name '${x.name}' has no source`);
    if (x.detail !== null && typeof x.detail !== 'string') fail(file, n, `name '${x.name}' detail is neither a string nor null`);
  }
  if (!Array.isArray(o.translations)) fail(file, n, 'translations is not an array');
  for (const t of o.translations) {
    requireKeys(t, ['image', 'va', 'direct', 'answering_paths', 'paths'], file, n, 'translation');
    if (!images.has(t.image)) fail(file, n, `translation image '${t.image}' is not in images.tsv`);
    if (!VA_RE.test(t.va)) fail(file, n, `translation va '${t.va}' is not a va`);
    if (typeof t.direct !== 'boolean') fail(file, n, 'translation direct is not a boolean');
    if (!isCount(t.answering_paths) || !isCount(t.paths)) fail(file, n, 'translation answering_paths / paths are not non-negative integers');
    if (t.answering_paths > t.paths) fail(file, n, `translation answering_paths ${t.answering_paths} exceeds paths ${t.paths}`);
  }
}

/**
 * Read one image's file pair in lockstep, validating everything. Yields `{header}` once (the two
 * image records), then `{fn, ann}` per function; returns after both end records check out.
 */
async function* readPair(pair, images) {
  const fFile = pair.files.functions, aFile = pair.files.annotate;
  const fIt = jsonLines(fFile)[Symbol.asyncIterator]();
  const aIt = jsonLines(aFile)[Symbol.asyncIterator]();
  try {
    yield* readPairRecords(pair, images, fIt, aIt);
  } finally {
    // Close both readers on every exit (end, failure, or an abandoned consumer).
    await fIt.return();
    await aIt.return();
  }
}

async function* readPairRecords(pair, images, fIt, aIt) {
  const fFile = pair.files.functions, aFile = pair.files.annotate;
  const img = pair.image;

  const fh = await fIt.next();
  if (fh.done) fail(fFile, 0, 'empty file (no image record)');
  const fHead = fh.value.obj;
  requireKeys(fHead, FN_IMAGE_KEYS, fFile, 1, 'image record');
  if (fHead.kind !== 'image') fail(fFile, 1, `first record kind is '${fHead.kind}', expected 'image'`);
  if (fHead.image_id !== img.id) fail(fFile, 1, `image_id '${fHead.image_id}' but the file is named for '${img.id}'`);
  if (fHead.program_sha256 !== img.sha256) fail(fFile, 1, `program_sha256 ${fHead.program_sha256} differs from images.tsv sha256 ${img.sha256} for ${img.id}`);
  if (fHead.language !== img.language) fail(fFile, 1, `language '${fHead.language}' differs from images.tsv ghidra_language '${img.language}' for ${img.id}`);
  for (const k of ['program', 'ghidra_version', 'compiler_spec']) if (typeof fHead[k] !== 'string' || !fHead[k]) fail(fFile, 1, `${k} is not a non-empty string`);
  if (!isCount(fHead.functions)) fail(fFile, 1, `functions ${JSON.stringify(fHead.functions)} is not a non-negative integer`);

  const ah = await aIt.next();
  if (ah.done) fail(aFile, 0, 'empty file (no image record)');
  const aHead = ah.value.obj;
  requireKeys(aHead, ANN_IMAGE_KEYS, aFile, 1, 'image record');
  if (aHead.kind !== 'image') fail(aFile, 1, `first record kind is '${aHead.kind}', expected 'image'`);
  if (aHead.image_id !== img.id) fail(aFile, 1, `image_id '${aHead.image_id}' but the file is named for '${img.id}'`);
  if (aHead.sha256 !== img.sha256) fail(aFile, 1, `sha256 ${aHead.sha256} differs from images.tsv sha256 ${img.sha256} for ${img.id}`);
  checkImageList(aHead.variants, images, aFile, 1, 'variants');
  checkImageList(aHead.graph_images, images, aFile, 1, 'graph_images');
  checkImageList(aHead.untranslatable_images, images, aFile, 1, 'untranslatable_images');
  const got = [...aHead.variants].sort().join(', ');
  const want = pair.variants.join(', ');
  if (got !== want) fail(aFile, 1, `variants [${got}] differ from the images.tsv rows whose code_image is ${img.id}: [${want}]`);

  yield { header: { functions: fHead, annotate: aHead } };

  const seen = new Set();
  let i = 0, decompiled = 0, failed = 0;
  for (;;) {
    const f = await fIt.next();
    const a = await aIt.next();
    if (f.done) fail(fFile, 0, `ended after ${i} functions with no end record`);
    if (a.done) fail(aFile, 0, `ended after ${i} functions with no end record`);
    const fo = f.value.obj, ao = a.value.obj;
    const fEnd = fo && fo.kind === 'end';
    const aEnd = ao && ao.kind === 'end';
    if (fEnd || aEnd) {
      if (!aEnd) fail(aFile, a.value.n, `has a function here but ${fFile} ends at line ${f.value.n} after ${i} functions`);
      if (!fEnd) fail(fFile, f.value.n, `has a function here but ${aFile} ends at line ${a.value.n} after ${i} functions`);
      requireKeys(fo, FN_END_KEYS, fFile, f.value.n, 'end record');
      requireKeys(ao, ANN_END_KEYS, aFile, a.value.n, 'end record');
      if (i !== fHead.functions) fail(fFile, f.value.n, `${i} function records but the image record says ${fHead.functions}`);
      if (fo.functions !== i) fail(fFile, f.value.n, `end record says ${fo.functions} functions, the file has ${i}`);
      if (fo.decompiled !== decompiled) fail(fFile, f.value.n, `end record says ${fo.decompiled} decompiled, the file has ${decompiled}`);
      if (fo.failed !== failed) fail(fFile, f.value.n, `end record says ${fo.failed} failed, the file has ${failed}`);
      if (ao.functions !== i) fail(aFile, a.value.n, `end record says ${ao.functions} functions, the file has ${i}`);
      if (!(await fIt.next()).done) fail(fFile, f.value.n + 1, 'content after the end record');
      if (!(await aIt.next()).done) fail(aFile, a.value.n + 1, 'content after the end record');
      return;
    }
    checkFunction(fo, fFile, f.value.n);
    checkAnnotation(ao, images, aFile, a.value.n);
    if (ao.va !== fo.va) fail(aFile, a.value.n, `va ${ao.va} but ${fFile} line ${f.value.n} is ${fo.va} — the files are not in the same order`);
    // annotate lists the functions file's own name first: {name, source "ghidra:<name_source>",
    // detail "thunk" | null}. It is the one source of every name, so it must agree.
    const g = ao.names[0];
    const want = { name: fo.name, source: `ghidra:${fo.name_source}`, detail: fo.thunk ? 'thunk' : null };
    if (!g || g.name !== want.name || g.source !== want.source || g.detail !== want.detail) {
      fail(aFile, a.value.n, `first name ${JSON.stringify(g ?? null)} is not the functions file's own name ${JSON.stringify(want)} (${fFile} line ${f.value.n})`);
    }
    if (seen.has(fo.va)) fail(fFile, f.value.n, `va ${fo.va} appears twice`);
    seen.add(fo.va);
    i++;
    if (fo.decomp !== null) decompiled++; else failed++;
    yield { fn: fo, ann: ao };
  }
}

/**
 * Which images.tsv code images have their export files, from the file names alone (no file is
 * read): `pairs` for the exported ones, `notExported` (each with its variants) for the code images
 * with neither file. A code image with one of its two files, a variant with files of its own, and a
 * file for an image outside images.tsv are hard failures.
 */
export function ghidraExportState({
  exportsDir = path.join(REPO_ROOT, GHIDRA_EXPORTS),
  imagesTsv = path.join(REPO_ROOT, GHIDRA_IMAGES),
} = {}) {
  const images = readImagesTsv(imagesTsv);
  if (!fs.existsSync(exportsDir) || !fs.statSync(exportsDir).isDirectory()) {
    fail(exportsDir, 0, `exports directory not found (set by CORPUS_GHIDRA_EXPORTS; images from ${imagesTsv})`);
  }
  const own = new Map();
  for (const name of fs.readdirSync(exportsDir)) {
    const m = name.match(/^(.+)\.(functions|annotate)\.jsonl$/);
    if (!m) continue;
    if (!images.has(m[1])) fail(path.join(exportsDir, name), 0, `image '${m[1]}' is not in ${imagesTsv}`);
    if (!own.has(m[1])) own.set(m[1], {});
    own.get(m[1])[m[2]] = path.join(exportsDir, name);
  }
  const pairs = [];
  const notExported = [];
  for (const img of images.values()) {
    const files = own.get(img.id);
    if (img.codeImage) {
      if (files) fail(Object.values(files)[0], 0, `${img.id} shares the code of ${img.codeImage} (images.tsv line ${img.line}) and must have no export files of its own`);
      continue;
    }
    const variants = [...images.values()].filter((v) => v.codeImage === img.id).map((v) => v.id).sort();
    if (!files) {
      notExported.push({ image: img.id, variants });
      continue;
    }
    for (const kind of ['functions', 'annotate']) {
      if (!files[kind]) {
        fail(path.join(exportsDir, `${img.id}.${kind}.jsonl`), 0,
          `missing — image ${img.id} (images.tsv line ${img.line}) has its ${kind === 'functions' ? 'annotate' : 'functions'} file; an image is exported as both files or neither`);
      }
    }
    pairs.push({ image: img, variants, files });
  }
  return { exportsDir, imagesTsv, images, pairs, notExported };
}

/**
 * Check the whole export set against images.tsv before anything is indexed: `ghidraExportState`,
 * then every exported pair passes `readPair` end to end. Returns the plan `ghidraDocs` walks.
 * Throws on the first violation.
 */
export async function verifyGhidraExports(opts = {}) {
  const plan = ghidraExportState(opts);
  for (const pair of plan.pairs) for await (const _ of readPair(pair, plan.images)) { /* validation only */ }
  return plan;
}

/** Wrap a list into lines of `per` entries so chunkCode can split a long list on line bounds. */
function wrapList(items, per = 8) {
  const out = [];
  for (let i = 0; i < items.length; i += per) out.push(`  ${items.slice(i, i + per).join(', ')}`);
  return out;
}

function ghidraDoc(pair, header, fn, ann, mtime) {
  const img = pair.image;
  const images = [img.id, ...pair.variants].join(' ');
  // Every name with its source, as `exemap annotate` lists them (Ghidra's own name first — checked
  // against the functions file in readPairRecords).
  const names = ann.names;
  const title = `${[...new Set(names.map((x) => x.name))].join(' / ')} @${fn.va} [${img.id}]`;
  const lines = [
    title,
    `image: ${img.id} sha256 ${img.sha256}${pair.variants.length ? ` (same code: ${pair.variants.join(', ')})` : ''}`,
    'names:',
    ...names.map((x) => `  ${x.name} (${x.source}${x.detail ? `: ${x.detail}` : ''})`),
    `block: ${fn.block}  size: ${fn.size}${fn.thunk ? `  thunk -> ${fn.thunk_target ?? 'no target'}` : ''}`,
    `callers (${fn.callers.length}):`,
    ...wrapList(fn.callers.map((c) => (c.function ? `${c.function} (site ${c.site})` : `site ${c.site} (no function)`))),
    `callees (${fn.callees.length}):`,
    ...wrapList(fn.callees),
    `translations (${ann.translations.length}):`,
    ...ann.translations.map((t) => `  ${t.image} ${t.va} (${t.direct ? 'direct' : 'indirect'}, ${t.answering_paths}/${t.paths} paths)`),
    '',
    fn.decomp !== null ? fn.decomp : `decompile failed: ${fn.decomp_error}`,
  ];
  const text = lines.join('\n');
  const meta = JSON.stringify({
    names,
    block: fn.block,
    size: fn.size,
    thunk: fn.thunk,
    thunk_target: fn.thunk_target,
    callers: fn.callers,
    callees: fn.callees,
    translations: ann.translations,
    graph_images: header.annotate.graph_images,
    untranslatable_images: header.annotate.untranslatable_images,
  });
  return {
    source: 'ghidra',
    path: `ghidra/${img.id}/${fn.va}`,
    title,
    mtime,
    // Per-function identity: an unchanged function skips even when the export is regenerated.
    fileHash: sha256(`${img.sha256}\0${images}\0${meta}\0${text}`),
    chunks: chunkCode(text, 140, 10),
    meta,
    imageId: img.id,
    imageSha256: img.sha256,
    va: fn.va,
    images,
  };
}

/** One doc per (image, function VA) across every exported image. `plan` is a
 *  `verifyGhidraExports()` result already computed in this run; without one, it verifies first. */
export async function* ghidraDocs(plan = null) {
  plan ??= await verifyGhidraExports();
  for (const pair of plan.pairs) {
    const mtime = Math.max(fs.statSync(pair.files.functions).mtimeMs, fs.statSync(pair.files.annotate).mtimeMs);
    let header = null;
    for await (const rec of readPair(pair, plan.images)) {
      if (rec.header) { header = rec.header; continue; }
      yield ghidraDoc(pair, header, rec.fn, rec.ann, mtime);
    }
  }
}

// Roots the Lua analyzer walks. Shipped game Lua + mod Lua. These are the only trees whose Lua
// files are structurally meaningful; everything else is prose/examples where parsing adds nothing.
const LUA_ROOTS = [
  'tools/wad_simulator/workshop_data/lua',
  'tools/wad_simulator/workshop_data/shipments',
];

/**
 * Lua static-analysis facts. One ingestion doc per class/module (chunk 0 carries the full
 * ClassAPI/DataAPI in `meta`), plus one row per high-cardinality data record so individual
 * registry entries (tMissionData["PmcCon001"], _tStarters[...], …) are addressable by key.
 *
 * fileHash mixes in the file's own text so unchanged files skip on re-ingest. The analyzer runs
 * at ingest time; search queries hit the LanceDB cache.
 */
export async function* luaApiDocs() {
  for (const relRoot of LUA_ROOTS) {
    const absRoot = path.join(REPO_ROOT, relRoot);
    if (!fs.existsSync(absRoot)) continue;
    for (const abs of walk(absRoot)) {
      if (!abs.endsWith('.lua')) continue;
      let text;
      try { text = fs.readFileSync(abs, 'utf8'); } catch { continue; }
      if (text.length > MAX_FILE_BYTES) continue;
      let api;
      try { api = luaAnalyzeFile(abs); } catch (e) {
        api = { kind: 'parse_error', error: e.message };
      }
      if (!api || api.kind === 'parse_error' || api.kind === 'walk_error') continue;

      const relPath = rel(abs);
      const title = api.kind === 'class' ? (api.class ?? path.basename(abs, '.lua')) : (api.module ?? path.basename(abs, '.lua'));
      const stat = fs.statSync(abs);

      // Chunk-0 doc: full ClassAPI/DataAPI in meta, short textual summary for FTS. Summary
      // includes method names + table-record keys so FTS surfaces the file for "PmcCon001" or
      // "GetMissionId" queries without a dedicated per-record row having to carry those terms.
      const methodNames = (api.methods_defined ?? []).map((m) => m.name);
      const tableKeys = [];
      for (const t of api.tables ?? []) {
        if (t.records) for (const r of t.records) if (r.key) tableKeys.push(r.key);
      }
      const summary = [
        `${api.kind}: ${title}`,
        api.inherit_chain?.length ? `inherits: ${api.inherit_chain.join(' <- ')}` : null,
        api.imports?.length ? `imports: ${api.imports.join(', ')}` : null,
        methodNames.length ? `methods: ${methodNames.join(', ')}` : null,
        tableKeys.length ? `records: ${tableKeys.slice(0, 100).join(', ')}` : null,
      ].filter(Boolean).join('\n');

      yield {
        source: 'lua_api',
        path: relPath,
        title,
        mtime: stat.mtimeMs,
        fileHash: sha256(text),
        meta: JSON.stringify(api),
        chunks: [summary],
      };

      // Per-record rows for record_map tables: one doc per record so a query like
      // "lua_records WifMissionData tMissionData sStarter=PmcBoss" can filter by scalar field.
      // Only emit for record_map shape — ordered lists and scalars are small enough to live in
      // the chunk-0 meta.
      for (const t of api.tables ?? []) {
        if (t.shape !== 'record_map' || !t.records?.length) continue;
        for (const rec of t.records) {
          if (!rec.key) continue;
          const recPath = `${relPath}#${t.name}.${rec.key}`;
          const recMeta = {
            kind: 'data_record',
            module: title,
            table: t.name,
            key: rec.key,
            line: rec.line ?? null,
            fields: rec.fields ?? {},
          };
          const recSummary = `${title}.${t.name}["${rec.key}"]: ${Object.entries(rec.fields ?? {})
            .map(([k, v]) => `${k}=${JSON.stringify(v)}`)
            .join(' ')}`;
          yield {
            source: 'lua_api',
            path: recPath,
            title: rec.key,
            mtime: stat.mtimeMs,
            fileHash: sha256(text + '::' + rec.key),
            meta: JSON.stringify(recMeta),
            chunks: [recSummary],
          };
        }
      }
    }
  }
}

/** Unified async iterator over requested source names. */
export async function* allDocs(names, { ghidraPlan = null } = {}) {
  for (const name of names) {
    if (name === 'memory') yield* memoryDocs();
    else if (name === 'conversation') yield* conversationDocs();
    else if (name === 'commit') yield* commitDocs();
    else if (name === 'ghidra') yield* ghidraDocs(ghidraPlan);
    else if (name === 'lua_api') yield* luaApiDocs();
    else yield* fileDocs(name);
  }
}

export { extractAddrs };
