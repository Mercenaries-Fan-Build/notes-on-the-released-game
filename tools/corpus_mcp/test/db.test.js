import { test } from 'node:test';
import assert from 'node:assert/strict';
import { esc } from '../src/db.js';

test('esc: doubles single quotes for safe SQL string literals', () => {
  assert.equal(esc("O'Brien"), "O''Brien");
  assert.equal(esc("docs/it's/a path.md"), "docs/it''s/a path.md");
  assert.equal(esc('no quotes'), 'no quotes');
  assert.equal(esc("'; DROP TABLE corpus; --"), "''; DROP TABLE corpus; --");
});
