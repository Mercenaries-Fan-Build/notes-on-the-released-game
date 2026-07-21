import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { parseEnv, applyEnv, loadEnvFile } from '../src/env.js';

test('parseEnv: basic key=value', () => {
  assert.deepEqual(parseEnv('FOO=bar\nBAZ=qux'), { FOO: 'bar', BAZ: 'qux' });
});

test('parseEnv: skips blanks and comments', () => {
  const out = parseEnv('# a comment\n\nFOO=bar\n   # indented comment\nBAZ=1');
  assert.deepEqual(out, { FOO: 'bar', BAZ: '1' });
});

test('parseEnv: strips optional export prefix', () => {
  assert.deepEqual(parseEnv('export FOO=bar'), { FOO: 'bar' });
});

test('parseEnv: trims whitespace around key and unquoted value', () => {
  assert.deepEqual(parseEnv('  FOO =  bar  '), { FOO: 'bar' });
});

test('parseEnv: double quotes honour escapes and preserve inner spaces/#', () => {
  assert.deepEqual(parseEnv('FOO="a b\\tc"'), { FOO: 'a b\tc' });
  assert.deepEqual(parseEnv('P="Represent this # sentence: "'), { P: 'Represent this # sentence: ' });
});

test('parseEnv: single quotes are literal', () => {
  assert.deepEqual(parseEnv("FOO='a\\nb'"), { FOO: 'a\\nb' });
});

test('parseEnv: trailing " #comment" only stripped on unquoted values', () => {
  assert.deepEqual(parseEnv('FOO=bar # trailing'), { FOO: 'bar' });
  assert.deepEqual(parseEnv('URL=http://x/y#frag'), { URL: 'http://x/y#frag' }); // no preceding space -> kept
});

test('parseEnv: ignores malformed lines and empty keys', () => {
  assert.deepEqual(parseEnv('nokey\n=novalue\n123BAD=x\nOK=1'), { OK: '1' });
});

test('parseEnv: later duplicate wins', () => {
  assert.deepEqual(parseEnv('FOO=1\nFOO=2'), { FOO: '2' });
});

test('applyEnv: does not clobber already-set vars, returns applied keys', () => {
  const env = { EXISTING: 'keep' };
  const applied = applyEnv({ EXISTING: 'new', FRESH: 'set' }, env);
  assert.equal(env.EXISTING, 'keep');
  assert.equal(env.FRESH, 'set');
  assert.deepEqual(applied, ['FRESH']);
});

test('loadEnvFile: reads a file into env without clobbering', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-env-'));
  const file = path.join(dir, '.env');
  fs.writeFileSync(file, 'A=1\nB=2\n');
  const env = { A: 'preset' };
  const applied = loadEnvFile(file, env);
  assert.equal(env.A, 'preset'); // preset wins
  assert.equal(env.B, '2');
  assert.deepEqual(applied, ['B']);
  fs.rmSync(dir, { recursive: true, force: true });
});

test('loadEnvFile: missing file is a no-op', () => {
  assert.deepEqual(loadEnvFile('/no/such/file/.env', {}), []);
});
