import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

// Exercises the source-walking generators in sources.js directly (no
// embeddings): ghidra decomp parsing + call-graph edges, conversation
// windowing/filtering, memory, commits, and the generic file walker. The whole
// suite runs against one throwaway git tree that every generator points into.

const here = path.dirname(fileURLToPath(import.meta.url));
const fx = (n) => fs.readFileSync(path.join(here, 'fixtures', n), 'utf8');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-src-'));

// Point config at the temp tree BEFORE importing config-backed modules.
process.env.CORPUS_ENV_FILE = path.join(root, 'no.env');
process.env.CORPUS_REPO_ROOT = root;
process.env.CORPUS_GHIDRA_DUMP = 'ghidra/dump.txt';
process.env.CORPUS_MEMORY_DIR = path.join(root, 'mem');
process.env.CORPUS_TRANSCRIPTS_DIR = path.join(root, 'transcripts');

let sources;

async function collect(iter) {
  const out = [];
  for await (const x of iter) out.push(x);
  return out;
}

before(async () => {
  fs.mkdirSync(path.join(root, 'docs'), { recursive: true });
  fs.mkdirSync(path.join(root, 'ghidra'), { recursive: true });
  fs.mkdirSync(path.join(root, 'mem'), { recursive: true });
  fs.mkdirSync(path.join(root, 'transcripts'), { recursive: true });

  fs.writeFileSync(path.join(root, 'docs', 'alpha.md'), '# Alpha\n\nMentions FUN_00478120 in a doc.\n');
  fs.writeFileSync(path.join(root, 'docs', 'skip.png'), 'binary-ish, wrong ext');
  fs.writeFileSync(path.join(root, 'docs', 'notes.txt'), 'Plain text note -> chunkText path.\n');
  fs.writeFileSync(path.join(root, 'docs', 'script.lua'), 'function decode() return FUN_00478120 end\n');
  fs.writeFileSync(path.join(root, 'docs', 'empty.md'), ''); // 0 bytes -> skipped by size guard
  // project source: dirs (.claude) absent here, so only the extraFiles resolve.
  fs.writeFileSync(path.join(root, 'AGENTS.md'), '# Agents\n\nProject-level guidance doc.\n');
  fs.writeFileSync(path.join(root, 'README.md'), '# Readme\n\nTop-level readme.\n');
  fs.writeFileSync(path.join(root, 'ghidra', 'dump.txt'), fx('ghidra_sample.txt'));
  fs.writeFileSync(path.join(root, 'mem', 'wavelet-decode-sample.md'), fx('memory_sample.md'));
  fs.writeFileSync(path.join(root, 'mem', 'ignore.txt'), 'not a .md memory file');
  fs.writeFileSync(path.join(root, 'transcripts', 'ignore.log'), 'not a .jsonl transcript');

  // Conversation fixture + programmatic extras that trigger the windowing and
  // filtering branches tiny transcripts never reach.
  const convo = path.join(root, 'transcripts', 'abc1234session.jsonl');
  fs.writeFileSync(convo, fx('conversation_sample.jsonl'));
  fs.appendFileSync(convo, [
    JSON.stringify({ type: 'system', message: { content: 'system-line-ignored' } }),
    JSON.stringify({ type: 'user', message: { content: 'ok' } }), // < 8 chars -> dropped
    JSON.stringify({ type: 'assistant', message: { content: [{ type: 'text', text: 'streaming budget detail sentence. '.repeat(120) }] } }),
    '',
  ].join('\n'));

  const git = (...a) => execFileSync('git', a, {
    cwd: root,
    env: {
      ...process.env,
      GIT_AUTHOR_NAME: 'Test', GIT_AUTHOR_EMAIL: 't@e.st',
      GIT_COMMITTER_NAME: 'Test', GIT_COMMITTER_EMAIL: 't@e.st',
    },
  });
  git('init', '-q');
  git('add', '-A');
  git('commit', '-q', '-m', 'Seed fixtures fixing FUN_00478120 decode');

  ({ default: sources } = { default: await import('../src/sources.js') });
});

after(() => fs.rmSync(root, { recursive: true, force: true }));

test('ghidraDocs: one doc per function with call-graph edges', async () => {
  const docs = await collect(sources.ghidraDocs());
  assert.equal(docs.length, 3);

  const f = docs.find((d) => d.path === 'ghidra/FUN_00478120');
  assert.ok(f, 'FUN_00478120 parsed');
  assert.equal(f.source, 'ghidra');
  assert.equal(f.fnAddr, '00478120');
  assert.match(f.title, /^FUN_00478120 @0x00478120 size=340$/);
  assert.ok(f.chunks.length >= 1);
  assert.ok(f.chunks[0].includes('==== FUN_00478120'), 'header kept as chunk prefix');

  const meta = JSON.parse(f.meta);
  assert.equal(meta.size, 340);
  assert.deepEqual(meta.callers, ['00478000']); // from the header
  assert.ok(meta.callees.includes('00478200'), 'callee extracted from body');
  assert.ok(!meta.callees.includes('00478120'), 'self-reference excluded from callees');
});

test('ghidraDocs: per-function fileHash so unchanged fns skip on redump', async () => {
  const a = await collect(sources.ghidraDocs());
  const b = await collect(sources.ghidraDocs());
  const ha = a.find((d) => d.fnAddr === '00478200').fileHash;
  const hb = b.find((d) => d.fnAddr === '00478200').fileHash;
  assert.equal(ha, hb);
  assert.notEqual(ha, a.find((d) => d.fnAddr === '00478120').fileHash);
});

test('memoryDocs: reads one fact per .md file, ignoring non-md', async () => {
  const docs = await collect(sources.memoryDocs());
  assert.equal(docs.length, 1); // ignore.txt skipped
  assert.equal(docs[0].source, 'memory');
  assert.equal(docs[0].path, 'memory/wavelet-decode-sample.md');
  assert.ok(docs[0].chunks.join('\n').includes('numerically matches the live capture'));
});

test('conversationDocs: windows real turns and strips tool/system noise', async () => {
  const docs = await collect(sources.conversationDocs());
  assert.equal(docs.length, 1);
  const d = docs[0];
  assert.equal(d.source, 'conversation');
  assert.equal(d.path, 'conversations/abc1234session.jsonl');
  assert.match(d.title, /How does FUN_00478120/);

  const body = d.chunks.join('\n');
  assert.ok(body.includes('[summary] Investigated the wavelet decoder'));
  assert.ok(body.includes('How does FUN_00478120 decode'));      // user turn
  assert.ok(body.includes('calls FUN_00478200'));                 // assistant turn
  assert.ok(body.includes('streaming budget code path'));         // inline reminder stripped, text kept
  assert.ok(body.includes('[claude:sub]'));                       // sidechain tagged

  assert.ok(!body.includes('secret-inline'), 'inline system-reminder removed');
  assert.ok(!body.includes('only-a-reminder'), 'reminder-only message dropped');
  assert.ok(!body.includes('API Error'), 'API Error message dropped');
  assert.ok(!body.includes('tool_use'), 'tool calls not indexed');
  assert.ok(!body.includes('system-line-ignored'), 'non-user/assistant turn skipped');
  assert.ok(!body.includes('[user] ok'), 'too-short turn dropped');
});

test('conversationDocs: windows a large transcript into multiple chunks', async () => {
  const [d] = await collect(sources.conversationDocs());
  // The appended ~4KB turn forces window flushing + a giant-turn hard split.
  assert.ok(d.chunks.length > 1, `expected multiple chunks, got ${d.chunks.length}`);
  for (const c of d.chunks) assert.ok(c.length <= 1800 * 1.6);
});

test('commitDocs: one doc per commit, first line is the title', async () => {
  const docs = await collect(sources.commitDocs());
  assert.ok(docs.length >= 1);
  const c = docs.find((d) => d.title.includes('Seed fixtures'));
  assert.ok(c, 'seed commit present');
  assert.equal(c.source, 'commit');
  assert.match(c.path, /^commit\/[0-9a-f]{12}$/);
  assert.ok(c.chunks[0].includes('FUN_00478120'));
});

test('fileDocs: honours the ext allow-list, size guard, and per-ext chunker', async () => {
  const docs = await collect(sources.fileDocs('doc'));
  const paths = docs.map((d) => d.path);
  assert.ok(paths.includes('docs/alpha.md'));      // markdown chunker
  assert.ok(paths.includes('docs/notes.txt'));     // plain-text chunker
  assert.ok(paths.includes('docs/script.lua'));    // code chunker
  assert.ok(!paths.some((p) => p.endsWith('.png')), '.png excluded by ext allow-list');
  assert.ok(!paths.includes('docs/empty.md'), '0-byte file skipped by size guard');
});

test('fileDocs: resolves extraFiles even when the configured dirs are absent', async () => {
  const docs = await collect(sources.fileDocs('project')); // .claude/ does not exist here
  const paths = docs.map((d) => d.path);
  assert.ok(paths.includes('AGENTS.md'), 'extraFiles entry that exists is picked up');
  assert.ok(paths.includes('README.md'));
});

test('allDocs: dispatches across every source kind', async () => {
  const docs = await collect(sources.allDocs(['doc', 'ghidra', 'memory', 'conversation', 'commit']));
  const bySource = new Set(docs.map((d) => d.source));
  for (const s of ['doc', 'ghidra', 'memory', 'conversation', 'commit']) {
    assert.ok(bySource.has(s), `allDocs dispatched ${s}`);
  }
});
