import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  sha256, normAddr, extractAddrs, chunkText, chunkMarkdown, chunkCode,
} from '../src/chunk.js';

test('sha256: stable, hex, 64 chars', () => {
  const a = sha256('hello');
  assert.match(a, /^[0-9a-f]{64}$/);
  assert.equal(a, sha256('hello'));
  assert.notEqual(a, sha256('world'));
});

test('normAddr: pads to 8 lowercase hex digits, strips leading zeros first', () => {
  assert.equal(normAddr('478120'), '00478120');
  assert.equal(normAddr('00478120'), '00478120');
  assert.equal(normAddr('E00B080C'), 'e00b080c');
  assert.equal(normAddr('0'), '00000000');
});

test('extractAddrs: normalizes and dedupes across spellings', () => {
  // FUN_00478120 and 0x478120 are the same normalized address -> one token.
  assert.equal(
    extractAddrs('FUN_00478120 calls 0x478120 and DAT_00df6b88'),
    '00478120 00df6b88',
  );
});

test('extractAddrs: matches 5-8 hex digit tokens only', () => {
  assert.equal(extractAddrs('0x1234'), '');            // 4 digits, ignored
  assert.equal(extractAddrs('0xabcde'), '000abcde');   // 5 digits, kept
  assert.equal(extractAddrs('LAB_0085ac90'), '0085ac90');
  assert.equal(extractAddrs('no addresses here'), '');
});

test('chunkText: short text -> single trimmed chunk', () => {
  assert.deepEqual(chunkText('  hello world  '), ['hello world']);
});

test('chunkText: empty / whitespace -> no chunks', () => {
  assert.deepEqual(chunkText('   '), []);
  assert.deepEqual(chunkText(''), []);
});

test('chunkText: long text splits into overlapping chunks covering the content', () => {
  const para = 'Lorem ipsum dolor sit amet. '.repeat(20).trim(); // ~540 chars
  const text = Array.from({ length: 8 }, (_, i) => `P${i} ${para}`).join('\n\n');
  const chunks = chunkText(text, 500, 50);
  assert.ok(chunks.length > 1, 'should split');
  for (const c of chunks) assert.ok(c.length > 20);
  // every source paragraph marker survives somewhere
  for (let i = 0; i < 8; i++) assert.ok(chunks.some((c) => c.includes(`P${i} `)), `P${i} missing`);
});

test('chunkText: a single oversized paragraph is hard-split on lines', () => {
  const giant = Array.from({ length: 40 }, (_, i) => `line ${i} with some filler text here`).join('\n');
  const chunks = chunkText(giant, 200, 30);
  assert.ok(chunks.length > 1);
});

test('chunkMarkdown: produces non-empty chunks and keeps section content', () => {
  const md = [
    '# Main Title',
    '',
    'An introductory paragraph long enough to be its own chunk of content here.',
    '',
    '## Details Section',
    '',
    'Body text describing details that does not repeat the earlier words.',
  ].join('\n');
  const chunks = chunkMarkdown(md);
  assert.ok(chunks.length >= 1);
  assert.ok(chunks.some((c) => c.includes('introductory paragraph')));
  assert.ok(chunks.some((c) => c.includes('describing details')));
});

test('chunkMarkdown: long subsection gets its heading prefixed onto spill chunks', () => {
  const body = 'sentence about streaming budgets and residency. '.repeat(60);
  const md = `# Top\n\n## Streaming\n\n${body}`;
  const chunks = chunkMarkdown(md);
  assert.ok(chunks.length > 1);
  // The heading line lives in the first chunk; later spill chunks that no longer
  // contain it are tagged with [Streaming].
  assert.ok(chunks.some((c) => c.startsWith('[Streaming]')));
});

test('chunkCode: short whitespace-only code yields no chunks', () => {
  assert.deepEqual(chunkCode('   \n  \n'), []);
});

test('chunkCode: short code stays whole; long code windows with overlap', () => {
  assert.deepEqual(chunkCode('int main() { return 0; }'), ['int main() { return 0; }']);
  const long = Array.from({ length: 300 }, (_, i) => `  do_thing(${i});`).join('\n');
  const chunks = chunkCode(long, 90, 12);
  assert.ok(chunks.length > 1);
  // overlap: last line of chunk 0 reappears near the start of chunk 1
  const tail0 = chunks[0].split('\n').slice(-12);
  assert.ok(tail0.some((l) => chunks[1].includes(l)));
});
