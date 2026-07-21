// MEMORY.md is auto-loaded into every session and silently truncates past ~24 KB. It reached
// 38.6 KB, and the third that fell off the end was the skins/DLC/asset-injection domain — so a
// character-import project ran with none of that domain in ambient view and re-derived work that
// was already recorded. Nothing failed; the overflow is invisible from inside the session.
//
// Hence a test rather than a lint script: the budget has to be something that BREAKS, not
// something someone remembers to check.

import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { MEMORY_DIR } from '../src/config.js';

const INDEX = path.join(MEMORY_DIR, 'MEMORY.md');

/** Harness budget is ~24,986 B; hold a margin so a couple of new entries cannot silently cross it. */
const BUDGET = 22_000;
const MAX_ENTRY_LINE = 250;

const present = fs.existsSync(INDEX);
const skip = present ? false : 'memory dir not present (fresh clone / CI)';

test('MEMORY.md fits the auto-load budget', { skip }, () => {
  const bytes = Buffer.byteLength(fs.readFileSync(INDEX, 'utf8'), 'utf8');
  assert.ok(
    bytes <= BUDGET,
    `MEMORY.md is ${bytes} B, over the ${BUDGET} B budget. It is auto-loaded and truncates SILENTLY — `
    + 'move entries into MEMORY-CATALOGUE.md (corpus-indexed, not auto-loaded) rather than trimming hooks.',
  );
});

test('MEMORY.md keeps the mandates in the loaded region', { skip }, () => {
  const text = fs.readFileSync(INDEX, 'utf8');
  const idx = text.indexOf('MANDATES');
  assert.ok(idx >= 0, 'MEMORY.md must carry a MANDATES section');
  const bytesBefore = Buffer.byteLength(text.slice(0, idx), 'utf8');
  // The rules are the one thing that must never be the part that gets cut.
  assert.ok(bytesBefore < 8_000, `MANDATES starts ${bytesBefore} B in; keep it near the top`);
});

test('MEMORY.md entry lines stay scannable', { skip }, () => {
  const lines = fs.readFileSync(INDEX, 'utf8').split(/\r?\n/);
  const tooLong = lines
    .map((l, i) => ({ n: i + 1, l }))
    .filter(({ l }) => l.startsWith('- [') && l.length > MAX_ENTRY_LINE);
  assert.equal(
    tooLong.length, 0,
    `router lines over ${MAX_ENTRY_LINE} chars belong in MEMORY-CATALOGUE.md: `
    + tooLong.map(({ n }) => `line ${n}`).join(', '),
  );
});

test('the offloaded catalogue exists and is not itself auto-loaded', { skip }, () => {
  const cat = path.join(MEMORY_DIR, 'MEMORY-CATALOGUE.md');
  assert.ok(fs.existsSync(cat), 'MEMORY-CATALOGUE.md must hold the full index');
  // It is allowed to be large precisely because only the corpus reads it.
  const entries = fs.readFileSync(cat, 'utf8').split(/\r?\n/).filter((l) => l.startsWith('- [')).length;
  assert.ok(entries > 100, `catalogue should hold the full index, found ${entries} entries`);
});
