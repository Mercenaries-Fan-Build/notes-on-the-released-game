import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

// Exercises the source-walking generators in sources.js directly (no
// embeddings): multi-image ghidra export parsing + verification, conversation
// windowing/filtering, memory, commits, and the generic file walker. The whole
// suite runs against one throwaway git tree that every generator points into.

const here = path.dirname(fileURLToPath(import.meta.url));
const fx = (n) => fs.readFileSync(path.join(here, 'fixtures', n), 'utf8');
const GHIDRA_FX = path.join(here, 'fixtures', 'ghidra');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-src-'));

// Point config at the temp tree BEFORE importing config-backed modules.
process.env.CORPUS_ENV_FILE = path.join(root, 'no.env');
process.env.CORPUS_REPO_ROOT = root;
process.env.CORPUS_GHIDRA_EXPORTS = 'ghidra_exports';
process.env.CORPUS_GHIDRA_IMAGES = 'ghidra_exports/images.tsv';
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
  fs.cpSync(GHIDRA_FX, path.join(root, 'ghidra_exports'), { recursive: true });
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

test('ghidraDocs: one doc per (image, va) with full caller/callee lists and translations', async () => {
  const docs = await collect(sources.ghidraDocs());
  assert.deepEqual(docs.map((d) => d.path).sort(), [
    'ghidra/pc-v1/0x00478000', 'ghidra/pc-v1/0x00478120', 'ghidra/pc-v1/0x00478200', 'ghidra/pc-v1/0x00478300',
    'ghidra/pc-v10/0x00479120', 'ghidra/pc-v10/0x00479200',
  ]);

  const f = docs.find((d) => d.path === 'ghidra/pc-v1/0x00478120');
  assert.equal(f.source, 'ghidra');
  assert.equal(f.imageId, 'pc-v1');
  assert.equal(f.imageSha256, '110616f7e08ac09b2c7e04f01c221c1d6819eab22d7b59bb21a7fac1c5055000');
  assert.equal(f.va, '0x00478120');
  assert.equal(f.images, 'pc-v1');
  assert.equal(f.title, 'FUN_00478120 / HudMinimap::Draw @0x00478120 [pc-v1]');
  const text = f.chunks.join('\n');
  assert.ok(text.includes('  HudMinimap::Draw (rtti: HudMinimap vtable +0x10)'), 'names listed with sources');
  assert.ok(text.includes('0x00478000 (site 0x00478034)'), 'named caller listed');
  assert.ok(text.includes('site 0x00500010 (no function)'), 'caller site outside any function listed');
  assert.ok(text.includes('ext:KERNEL32.DLL!Sleep'), 'import callee listed');
  assert.ok(text.includes('  pc-v10 0x00479120 (direct, 3/5 paths)'), 'translation listed');
  assert.ok(text.includes('int FUN_00478120(int track,float *out)'), 'decomp included');

  const meta = JSON.parse(f.meta);
  assert.equal(meta.size, 340);
  assert.equal(meta.block, '.text');
  assert.deepEqual(meta.names.map((n) => [n.name, n.source]), [['FUN_00478120', 'ghidra:DEFAULT'], ['HudMinimap::Draw', 'rtti']]);
  assert.equal(text.split('\n').filter((l) => l.startsWith('  FUN_00478120 (')).length, 1, "Ghidra's name is listed once");
  assert.deepEqual(meta.callers, [{ site: '0x00478034', function: '0x00478000' }, { site: '0x00500010', function: null }]);
  assert.deepEqual(meta.callees, ['0x00478200', '0x00478300', 'ext:KERNEL32.DLL!Sleep', '*0x00a01234', '*stack:-0x1c', '?', 'sys:2']);
  assert.deepEqual(meta.translations, [{ image: 'pc-v10', va: '0x00479120', direct: true, answering_paths: 3, paths: 5 }]);
});

test('ghidraDocs: duplicate names are separate docs; a decompile failure is indexed with its reason', async () => {
  const docs = await collect(sources.ghidraDocs());
  const breaks = docs.filter((d) => d.imageId === 'pc-v1' && d.title.startsWith('__break @'));
  assert.deepEqual(breaks.map((d) => d.va).sort(), ['0x00478200', '0x00478300']);
  const failed = docs.find((d) => d.path === 'ghidra/pc-v1/0x00478200');
  assert.ok(failed.chunks.join('\n').includes('decompile failed: Decompiler process timed out after 60 seconds'));
  const thunk = docs.find((d) => d.path === 'ghidra/pc-v1/0x00478300');
  assert.ok(thunk.chunks[0].includes('thunk -> 0x00478200'));
});

test('ghidraDocs: a code image lists its variants in the images column', async () => {
  const docs = await collect(sources.ghidraDocs());
  for (const d of docs.filter((x) => x.imageId === 'pc-v10')) assert.equal(d.images, 'pc-v10 pc-v10-de');
  assert.ok(!docs.some((d) => d.imageId === 'pc-v10-de'), 'a variant has no docs of its own');
});

test('ghidraDocs: per-function fileHash so unchanged fns skip on re-export', async () => {
  const a = await collect(sources.ghidraDocs());
  const b = await collect(sources.ghidraDocs());
  const hash = (docs, p) => docs.find((d) => d.path === p).fileHash;
  assert.equal(hash(a, 'ghidra/pc-v1/0x00478200'), hash(b, 'ghidra/pc-v1/0x00478200'));
  assert.notEqual(hash(a, 'ghidra/pc-v1/0x00478200'), hash(a, 'ghidra/pc-v1/0x00478300'));
});

/** A fresh copy of the fixture export set, with `mutate(dir)` applied, verified. */
async function verifyMutated(mutate) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-gx-'));
  try {
    fs.cpSync(GHIDRA_FX, dir, { recursive: true });
    mutate(dir);
    return await sources.verifyGhidraExports({ exportsDir: dir, imagesTsv: path.join(dir, 'images.tsv') });
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}
const editLines = (file, fn) => fs.writeFileSync(file, fn(fs.readFileSync(file, 'utf8').trimEnd().split('\n')).join('\n') + '\n');
const editRecord = (file, idx, fn) => editLines(file, (ls) => { ls[idx] = JSON.stringify(fn(JSON.parse(ls[idx]))); return ls; });

test('verifyGhidraExports: the fixture set verifies', async () => {
  const plan = await verifyMutated(() => {});
  assert.deepEqual(plan.pairs.map((p) => [p.image.id, p.variants]), [['pc-v1', []], ['pc-v10', ['pc-v10-de']]]);
  assert.deepEqual(plan.notExported, []);
});

test('verifyGhidraExports: every callee form of the FnMnemonicSig grammar verifies', async () => {
  const callees = ['0x00478120', 'ext:KERNEL32.DLL!TlsGetValue', '*0x0244f59c', '*stack:0x10', '*stack:-0x68', '?', 'sys:988'];
  await verifyMutated((d) => editRecord(path.join(d, 'pc-v1.functions.jsonl'), 1, (o) => ({ ...o, callees })));
});

test('verifyGhidraExports: a thunk to an import names it as ext:<library>!<name>', async () => {
  const asThunk = (d, target) => {
    editRecord(path.join(d, 'pc-v1.functions.jsonl'), 1, (o) => ({ ...o, thunk: true, thunk_target: target }));
    editRecord(path.join(d, 'pc-v1.annotate.jsonl'), 1, (o) => ({ ...o, names: [{ ...o.names[0], detail: 'thunk' }] }));
  };
  await verifyMutated((d) => asThunk(d, 'ext:D3DX9_36.DLL!D3DXVec3TransformCoord'));
  await assert.rejects(
    () => verifyMutated((d) => asThunk(d, 'D3DXVec3TransformCoord')),
    /thunk_target 'D3DXVec3TransformCoord' is neither null, a va, nor ext:<library>!<name>/,
  );
});

test('verifyGhidraExports: a code image with neither file is listed as not exported, with its variants', async () => {
  const plan = await verifyMutated((d) => { fs.rmSync(path.join(d, 'pc-v10.functions.jsonl')); fs.rmSync(path.join(d, 'pc-v10.annotate.jsonl')); });
  assert.deepEqual(plan.pairs.map((p) => p.image.id), ['pc-v1']);
  assert.deepEqual(plan.notExported, [{ image: 'pc-v10', variants: ['pc-v10-de'] }]);
});

test('verifyGhidraExports: hard failures name the file and the problem', async () => {
  const cases = [
    ['an image with only one of its two files', (d) => fs.rmSync(path.join(d, 'pc-v10.annotate.jsonl')),
      /pc-v10\.annotate\.jsonl: missing — image pc-v10 \(images\.tsv line 3\) has its functions file; an image is exported as both files or neither/],
    ['a variant its code image does not list', (d) => editRecord(path.join(d, 'pc-v10.annotate.jsonl'), 0, (o) => ({ ...o, variants: [] })),
      /pc-v10\.annotate\.jsonl:1: variants \[\] differ from the images\.tsv rows whose code_image is pc-v10: \[pc-v10-de\]/],
    ['a variant with files of its own', (d) => fs.copyFileSync(path.join(d, 'pc-v10.functions.jsonl'), path.join(d, 'pc-v10-de.functions.jsonl')),
      /pc-v10-de\.functions\.jsonl: pc-v10-de shares the code of pc-v10/],
    ['a file for an image outside images.tsv', (d) => fs.copyFileSync(path.join(d, 'pc-v1.annotate.jsonl'), path.join(d, 'pc-v2.annotate.jsonl')),
      /pc-v2\.annotate\.jsonl: image 'pc-v2' is not in/],
    ['a program sha256 that differs from images.tsv', (d) => editRecord(path.join(d, 'pc-v1.functions.jsonl'), 0, (o) => ({ ...o, program_sha256: '0'.repeat(64) })),
      /pc-v1\.functions\.jsonl:1: program_sha256 0+ differs from images\.tsv sha256/],
    ['an annotate sha256 that differs from images.tsv', (d) => editRecord(path.join(d, 'pc-v1.annotate.jsonl'), 0, (o) => ({ ...o, sha256: 'f'.repeat(64) })),
      /pc-v1\.annotate\.jsonl:1: sha256 f+ differs/],
    ['annotate in a different order', (d) => editLines(path.join(d, 'pc-v1.annotate.jsonl'), (ls) => [ls[0], ls[2], ls[1], ...ls.slice(3)]),
      /pc-v1\.annotate\.jsonl:2: va 0x00478120 but .*pc-v1\.functions\.jsonl line 2 is 0x00478000 — the files are not in the same order/],
    ['a missing end record', (d) => editLines(path.join(d, 'pc-v1.functions.jsonl'), (ls) => ls.slice(0, -1)),
      /pc-v1\.functions\.jsonl: ended after 4 functions with no end record/],
    ['annotate with fewer functions', (d) => editLines(path.join(d, 'pc-v1.annotate.jsonl'), (ls) => [...ls.slice(0, 4), ls[5]]),
      /pc-v1\.functions\.jsonl:5: has a function here but .*pc-v1\.annotate\.jsonl ends at line 5 after 3 functions/],
    ['an end record count that disagrees', (d) => editRecord(path.join(d, 'pc-v1.functions.jsonl'), 5, (o) => ({ ...o, failed: 0 })),
      /pc-v1\.functions\.jsonl:6: end record says 0 failed, the file has 1/],
    ['an image record function count that disagrees', (d) => editRecord(path.join(d, 'pc-v10.functions.jsonl'), 0, (o) => ({ ...o, functions: 3 })),
      /pc-v10\.functions\.jsonl:4: 2 function records but the image record says 3/],
    ['an unknown field', (d) => editRecord(path.join(d, 'pc-v1.functions.jsonl'), 1, (o) => ({ ...o, comment: 'x' })),
      /pc-v1\.functions\.jsonl:2: function record keys differ from the export contract \(missing: none; unknown: comment\)/],
    ['an unknown callee token', (d) => editRecord(path.join(d, 'pc-v1.functions.jsonl'), 1, (o) => ({ ...o, callees: ['FUN_00478120'] })),
      /pc-v1\.functions\.jsonl:2: callee "FUN_00478120" is not a known callee token/],
    ['both decomp and decomp_error', (d) => editRecord(path.join(d, 'pc-v1.functions.jsonl'), 1, (o) => ({ ...o, decomp_error: 'x' })),
      /pc-v1\.functions\.jsonl:2: exactly one of decomp \/ decomp_error must be set/],
    ['a translation into an unknown image', (d) => editRecord(path.join(d, 'pc-v1.annotate.jsonl'), 2, (o) => ({ ...o, translations: [{ ...o.translations[0], image: 'x360-zz' }] })),
      /pc-v1\.annotate\.jsonl:3: translation image 'x360-zz' is not in images\.tsv/],
    ['a first annotate name that is not the functions file name', (d) => editRecord(path.join(d, 'pc-v1.annotate.jsonl'), 1, (o) => ({ ...o, names: o.names.slice(1) })),
      /pc-v1\.annotate\.jsonl:2: first name null is not the functions file's own name \{"name":"FUN_00478000","source":"ghidra:DEFAULT","detail":null\}/],
    ['a thunk whose annotate name does not say thunk', (d) => editRecord(path.join(d, 'pc-v1.annotate.jsonl'), 4, (o) => ({ ...o, names: [{ ...o.names[0], detail: null }] })),
      /pc-v1\.annotate\.jsonl:5: first name .* is not the functions file's own name \{"name":"__break","source":"ghidra:USER_DEFINED","detail":"thunk"\}/],
    ['a repeated va', (d) => { for (const f of ['pc-v1.functions.jsonl', 'pc-v1.annotate.jsonl']) editRecord(path.join(d, f), 2, (o) => ({ ...o, va: '0x00478000' })); },
      /pc-v1\.functions\.jsonl:3: va 0x00478000 appears twice/],
  ];
  for (const [what, mutate, re] of cases) {
    await assert.rejects(() => verifyMutated(mutate), re, what);
  }
});

test('verifyGhidraExports: a missing exports directory is a hard failure', async () => {
  await assert.rejects(
    () => sources.verifyGhidraExports({ exportsDir: path.join(root, 'no-such-dir'), imagesTsv: path.join(GHIDRA_FX, 'images.tsv') }),
    /no-such-dir: exports directory not found/,
  );
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
