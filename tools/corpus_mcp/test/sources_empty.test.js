import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

// Points config at an empty, non-git tree with missing memory/transcripts dirs
// and missing ghidra exports, so every "source absent" guard branch fires:
// the optional sources yield nothing, and the ghidra source (required) throws.
// No embeddings.

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-empty-'));
process.env.CORPUS_ENV_FILE = path.join(root, 'no.env');
process.env.CORPUS_REPO_ROOT = root;
process.env.CORPUS_GHIDRA_EXPORTS = 'missing/exports';
process.env.CORPUS_GHIDRA_IMAGES = 'missing/images.tsv';
process.env.CORPUS_MEMORY_DIR = path.join(root, 'no-memory');
process.env.CORPUS_TRANSCRIPTS_DIR = path.join(root, 'no-transcripts');

let sources;
async function collect(iter) { const o = []; for await (const x of iter) o.push(x); return o; }

before(async () => { sources = await import('../src/sources.js'); });
after(() => fs.rmSync(root, { recursive: true, force: true }));

test('fileDocs: missing configured dir yields nothing (walk guard)', async () => {
  assert.deepEqual(await collect(sources.fileDocs('doc')), []);
});

test('memoryDocs: missing memory dir yields nothing', async () => {
  assert.deepEqual(await collect(sources.memoryDocs()), []);
});

test('conversationDocs: missing transcripts dir yields nothing', async () => {
  assert.deepEqual(await collect(sources.conversationDocs()), []);
});

test('ghidraDocs: a missing images table is a hard failure, not an empty source', async () => {
  await assert.rejects(() => collect(sources.ghidraDocs()), /missing\/images\.tsv: images table not found/);
});

test('commitDocs: non-git tree is handled gracefully', async () => {
  assert.deepEqual(await collect(sources.commitDocs()), []);
});
