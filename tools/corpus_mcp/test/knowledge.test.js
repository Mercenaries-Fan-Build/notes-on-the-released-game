import test from 'node:test';
import assert from 'node:assert/strict';
import {
  splitFrontMatter, knowledgeMeta, readMeta, standingWeight,
  STATUS, STATUS_WEIGHT, EVIDENCE_WEIGHT,
} from '../src/knowledge.js';

test('splitFrontMatter: separates front-matter from body', () => {
  const { fm, body } = splitFrontMatter('---\nstatus: current\n---\nreal text\n');
  assert.equal(fm.status, 'current');
  assert.equal(body.trim(), 'real text');
});

test('splitFrontMatter: a document without front-matter is returned untouched', () => {
  const text = 'no front matter here\n---\nnot a delimiter at the start\n';
  const { fm, body } = splitFrontMatter(text);
  assert.deepEqual(fm, {});
  assert.equal(body, text);
});

test('knowledgeMeta: parses inline and block lists', () => {
  const inline = knowledgeMeta('---\nsupersedes: [docs/a.md, docs/b.md]\n---\nx');
  assert.deepEqual(inline.supersedes, ['docs/a.md', 'docs/b.md']);

  const block = knowledgeMeta('---\nsupersedes:\n  - docs/a.md\n  - docs/b.md\n---\nx');
  assert.deepEqual(block.supersedes, ['docs/a.md', 'docs/b.md']);
});

test('knowledgeMeta: a single scalar supersedes becomes a list', () => {
  assert.deepEqual(knowledgeMeta('---\nsupersedes: docs/a.md\n---\nx').supersedes, ['docs/a.md']);
});

test('knowledgeMeta: undeclared documents produce null, so ingest stores nothing', () => {
  assert.equal(knowledgeMeta('# just a heading\n\nbody\n'), null);
  // existing memory front-matter declares none of the contract fields
  assert.equal(knowledgeMeta('---\nname: foo\ndescription: bar\nmetadata:\n  type: project\n---\nbody'), null);
});

test('knowledgeMeta: rejects values outside the contract rather than trusting them', () => {
  assert.equal(knowledgeMeta('---\nstatus: probably-fine\n---\nx'), null);
  assert.equal(knowledgeMeta('---\nevidence: vibes\n---\nx'), null);
});

test('standingWeight: undeclared knowledge is unchanged (1.0)', () => {
  assert.equal(standingWeight({}), 1.0);
  assert.equal(standingWeight(readMeta('')), 1.0);
});

test('standingWeight: superseded and retracted are demoted, in that order', () => {
  const current = standingWeight({ status: STATUS.CURRENT });
  const superseded = standingWeight({ status: STATUS.SUPERSEDED });
  const retracted = standingWeight({ status: STATUS.RETRACTED });
  assert.ok(retracted < superseded, 'retracted must rank below superseded');
  assert.ok(superseded < current, 'superseded must rank below current');
  assert.equal(superseded, STATUS_WEIGHT[STATUS.SUPERSEDED]);
});

test('standingWeight: evidence grade separates a proven claim from a guess', () => {
  assert.ok(standingWeight({ evidence: 'speculative' }) < standingWeight({ evidence: 'proven' }));
  assert.equal(standingWeight({ evidence: 'inferred' }), EVIDENCE_WEIGHT.inferred);
});

test('standingWeight: a superseded claim loses to a current one regardless of evidence grade', () => {
  // the whole point of the contract: a correction must be able to outrank the doc it corrects,
  // even when the older doc calls itself proven.
  assert.ok(standingWeight({ status: STATUS.SUPERSEDED, evidence: 'proven' })
    < standingWeight({ status: STATUS.CURRENT, evidence: 'speculative' }));
});

test('readMeta: ghidra rows keep their own shape and score neutrally', () => {
  const ghidra = JSON.stringify({ size: 120, callers: ['00478120'], callees: [] });
  assert.equal(standingWeight(readMeta(ghidra)), 1.0);
  assert.deepEqual(readMeta('not json'), {});
});

test('splitFrontMatter: CRLF does not silently eat the last key', () => {
  // Regression. `end` points at the '\n' closing the final key line; on CRLF that line's own
  // '\r' sits at end-1, so the last key kept a trailing '\r' and failed the key regex — dropping
  // exactly one field, always the last, with no error. Most files in this repo are CRLF, so this
  // quietly ate a field from nearly every doc graded during the cull.
  const crlf = '---\r\nstatus: current\r\nevidence: proven\r\n---\r\nbody';
  const lf = '---\nstatus: current\nevidence: proven\n---\nbody';
  assert.deepEqual(knowledgeMeta(crlf), knowledgeMeta(lf));
  assert.equal(knowledgeMeta(crlf).evidence, 'proven');
});

test('splitFrontMatter: CRLF list values survive too', () => {
  assert.deepEqual(knowledgeMeta('---\r\nsupersedes: [docs/a.md, docs/b.md]\r\n---\r\nx').supersedes,
    ['docs/a.md', 'docs/b.md']);
});

test('parseYamlLite: block scalars keep their body, not the bare pipe', () => {
  // `witness: |` is the natural way to write a multi-line witness, and both verification agents
  // used it. Storing the literal '|' is worse than storing nothing: witness is the field that
  // says HOW we know, so a '|' there silently converts evidence into a shrug.
  const m = knowledgeMeta('---\nevidence: proven\nwitness: |\n  ran probe X over vz.wad\n  62,624/62,624 unit-norm\n---\nbody');
  assert.equal(m.evidence, 'proven');
  assert.match(m.witness, /ran probe X over vz\.wad/);
  assert.match(m.witness, /62,624/);
  assert.notEqual(m.witness, '|');
});

test('parseYamlLite: folded scalars join with spaces, and CRLF works too', () => {
  const m = knowledgeMeta('---\r\nwitness: >\r\n  first line\r\n  second line\r\n---\r\nbody');
  assert.equal(m.witness, 'first line second line');
});

test('parseYamlLite: a key after a block scalar is still parsed', () => {
  const m = knowledgeMeta('---\nwitness: |\n  some proof\nstatus: retracted\n---\nx');
  assert.equal(m.witness, 'some proof');
  assert.equal(m.status, 'retracted');
});
