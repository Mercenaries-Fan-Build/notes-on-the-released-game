import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import { execFileSync } from 'node:child_process';
import {
  REPO_ROOT, SOURCES, MEMORY_DIR, TRANSCRIPTS_DIR, GHIDRA_DUMP,
  MAX_FILE_BYTES, CONVO_WINDOW,
} from './config.js';
import { chunkMarkdown, chunkText, chunkCode, sha256, extractAddrs, normAddr } from './chunk.js';

/** A document = one ingestion unit: { source, path, title, mtime, fileHash, chunks: [text] , fnAddr?, meta? } */

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
    yield {
      source: sourceName,
      path: rel(file),
      title: rel(file),
      mtime: stat.mtimeMs,
      fileHash: sha256(text),
      chunks: chunksFor(file, text),
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

const FN_HEADER_RE = /^==== (\S+) @0x([0-9a-fA-F]+)\s+size=(\d+)\s+callers=\[([^\]]*)\]/;

/** Ghidra full-decomp dump -> one doc PER FUNCTION (27k), keyed by address.
 *  fileHash mixes in the function's own text so unchanged functions are
 *  skipped even when the dump file is regenerated. */
export async function* ghidraDocs() {
  const file = path.join(REPO_ROOT, GHIDRA_DUMP);
  if (!fs.existsSync(file)) {
    console.error(`[ghidra] dump not found: ${file} — skipping`);
    return;
  }
  const stat = fs.statSync(file);
  const rl = readline.createInterface({
    input: fs.createReadStream(file, 'utf8'),
    crlfDelay: Infinity,
  });
  let header = null;
  let buf = [];
  const flush = () => {
    if (!header) return null;
    const [, name, addr, size, callersRaw] = header;
    const body = buf.join('\n').trim();
    const fnAddr = normAddr(addr);
    // Call-graph edges: callers come from the export header, callees are the
    // FUN_ symbols referenced in the decompiled body (minus self).
    const callers = [...new Set(
      (callersRaw.match(/FUN_([0-9a-fA-F]+)/g) || []).map((s) => normAddr(s.slice(4))),
    )];
    const callees = [...new Set(
      (body.match(/FUN_([0-9a-fA-F]+)/g) || []).map((s) => normAddr(s.slice(4))),
    )].filter((a) => a !== fnAddr);
    const doc = {
      source: 'ghidra',
      path: `ghidra/${name}`,
      title: `${name} @0x${fnAddr} size=${size}`,
      mtime: stat.mtimeMs,
      fileHash: sha256(body),
      fnAddr,
      meta: JSON.stringify({ size: Number(size), callers, callees }),
      chunks: chunkCode(`${header[0]}\n${body}`, 140, 10),
    };
    return doc.chunks.length ? doc : null;
  };
  for await (const line of rl) {
    const m = line.match(FN_HEADER_RE);
    if (m) {
      const doc = flush();
      if (doc) yield doc;
      header = m;
      header[0] = line; // keep full header line (has callers) as chunk prefix
      buf = [];
    } else if (header && !line.startsWith('====================')) {
      buf.push(line);
    }
  }
  const doc = flush();
  if (doc) yield doc;
}

/** Unified async iterator over requested source names. */
export async function* allDocs(names) {
  for (const name of names) {
    if (name === 'memory') yield* memoryDocs();
    else if (name === 'conversation') yield* conversationDocs();
    else if (name === 'commit') yield* commitDocs();
    else if (name === 'ghidra') yield* ghidraDocs();
    else yield* fileDocs(name);
  }
}

export { extractAddrs };
