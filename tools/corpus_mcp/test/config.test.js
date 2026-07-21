import { test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';

// config.js reads process.env at module-evaluation time, so each case is
// evaluated in a fresh child process with a controlled environment. A bogus
// CORPUS_ENV_FILE keeps any real local .env from leaking into the assertions.
const here = path.dirname(fileURLToPath(import.meta.url));
const configUrl = pathToFileURL(path.join(here, '..', 'src', 'config.js')).href;
const BOGUS_ENV = path.join(here, 'no-such.env');

/** Import config.js in a child with `env` and return the named exports as JSON. */
function loadConfig(env, keys = ['TABLE_NAME', 'CHUNK_TARGET', 'DB_PATH', 'REPO_ROOT', 'MAX_FILE_BYTES']) {
  const script =
    `import(${JSON.stringify(configUrl)}).then(c => {` +
    `const pick = ${JSON.stringify(keys)};` +
    `process.stdout.write(JSON.stringify(Object.fromEntries(pick.map(k => [k, c[k]]))));` +
    `}).catch(e => { console.error(e.message); process.exit(3); });`;
  const out = execFileSync(process.execPath, ['-e', script], {
    encoding: 'utf8',
    env: { CORPUS_ENV_FILE: BOGUS_ENV, ...env },
  });
  return JSON.parse(out);
}

test('config: sane defaults when nothing is overridden', () => {
  const c = loadConfig({});
  assert.equal(c.TABLE_NAME, 'corpus');
  assert.equal(c.CHUNK_TARGET, 1400);
  assert.equal(c.MAX_FILE_BYTES, 4 * 1024 * 1024);
  assert.ok(c.DB_PATH.replace(/\\/g, '/').endsWith('storage/corpus_lancedb'));
});

test('config: env vars override string and numeric settings', () => {
  const c = loadConfig({ CORPUS_TABLE: 'mytable', CORPUS_CHUNK_TARGET: '999' });
  assert.equal(c.TABLE_NAME, 'mytable');
  assert.equal(c.CHUNK_TARGET, 999);
  assert.equal(typeof c.CHUNK_TARGET, 'number');
});

test('config: CORPUS_REPO_ROOT retargets DB_PATH default at another tree', () => {
  const root = path.resolve('/tmp/some/project');
  const c = loadConfig({ CORPUS_REPO_ROOT: root });
  assert.equal(path.resolve(c.REPO_ROOT), root);
  assert.equal(path.resolve(c.DB_PATH), path.resolve(root, 'storage', 'corpus_lancedb'));
});

test('config: explicit CORPUS_DB wins over the derived default', () => {
  const c = loadConfig({ CORPUS_DB: '/data/lance' });
  assert.equal(path.resolve(c.DB_PATH), path.resolve('/data/lance'));
});

test('config: a non-numeric numeric override is rejected loudly', () => {
  assert.throws(
    () => loadConfig({ CORPUS_CHUNK_TARGET: 'notanumber' }),
    /must be a number/,
  );
});
