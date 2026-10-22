import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// The bridge client (src/ghidra_bridge.js) against a stand-in analyzeHeadless
// (test/fixtures/fake_headless — no extension, so `node --test` does not take it for a test file)
// that speaks the GhidraBridge.java protocol — no Ghidra needed.
// pc-v1 and pc-v10 share one project; pc-v10-de is pc-v10's regional variant.

const here = path.dirname(fileURLToPath(import.meta.url));
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-gb-'));
process.env.CORPUS_ENV_FILE = path.join(root, 'no.env');
process.env.CORPUS_REPO_ROOT = root;
process.env.CORPUS_GHIDRA_IMAGES = 'images.tsv';
process.env.CORPUS_GHIDRA_PROJECTS = 'projects.tsv';
process.env.CORPUS_GHIDRA_BRIDGE_START_MS = '5000';
process.env.CORPUS_GHIDRA_BRIDGE_REQUEST_MS = '1500';

let B;
const write = (rel, text) => { fs.mkdirSync(path.dirname(path.join(root, rel)), { recursive: true }); fs.writeFileSync(path.join(root, rel), text); };

before(async () => {
  fs.copyFileSync(path.join(here, 'fixtures', 'ghidra', 'images.tsv'), path.join(root, 'images.tsv'));
  write('projects.tsv', [
    'image_id\tproject_dir\tproject_name\tprogram\tsettings_dir\timports\tcode_blocks',
    'pc-v1\tp/shared/proj\tshared\tv1.exe\t-\t-\t.text',
    'pc-v10\tp/shared/proj\tshared\tv10.exe\t-\t-\t.text',
    '',
  ].join('\n'));
  write('p/shared/proj/shared.gpr', '');
  write('tools/wad_simulator/.mercs2-local.toml', `ghidra_headless = "${path.join(here, 'fixtures', 'fake_headless')}"\n`);
  B = await import('../src/ghidra_bridge.js');
});

after(async () => {
  B.killAllBridges();
  fs.rmSync(root, { recursive: true, force: true });
});

test('a bridge starts on the first request, answers, and stops cleanly', async () => {
  delete process.env.FAKE_HEADLESS_MODE;
  const r = await B.ghidraRequest('pc-v1', 'echo', { va: '0x00401000' });
  assert.equal(r.served_by, 'pc-v1');
  assert.equal(r.result.va, '0x00401000');
  assert.deepEqual(B.listBridges().map((b) => [b.image, b.state, b.requests]), [['pc-v1', 'running', 1]]);
  const s = await B.stopBridge('pc-v1');
  assert.equal(s.stopped, 'pc-v1');
  assert.deepEqual(B.listBridges(), []);
  assert.ok(!fs.existsSync(path.join(os.tmpdir(), `m2gb-${process.pid}-pc-v1.sock`)), 'the socket is gone after the stop');
});

test('an error response rejects that request and leaves the bridge running', async () => {
  await assert.rejects(() => B.ghidraRequest('pc-v1', 'fail'), /pc-v1: fail: fake failure/);
  assert.equal((await B.ghidraRequest('pc-v1', 'info')).result.image_id, 'pc-v1');
  await B.stopBridge('pc-v1');
});

test('a regional variant is served by its code image, and a shared project serves one image at a time', async () => {
  const r = await B.ghidraRequest('pc-v10-de', 'info');
  assert.equal(r.served_by, 'pc-v10');
  await assert.rejects(() => B.ghidraRequest('pc-v1', 'info'), /p\/shared\/proj\/shared of pc-v1 is held by the running pc-v10 bridge; stop it first/);
  await B.stopBridge('pc-v10-de');
});

test('a request that times out stops the bridge; the next request starts a new one', async () => {
  await assert.rejects(() => B.ghidraRequest('pc-v1', 'hang'), /hang took longer than 1500 ms; the bridge was stopped/);
  assert.match(B.listBridges()[0].state, /^closed: hang timed out/);
  assert.equal((await B.ghidraRequest('pc-v1', 'info')).result.image_id, 'pc-v1');
  await B.stopBridge('pc-v1');
});

test('a headless run that exits or reports a script error before listening is an error with its log tail', async () => {
  process.env.FAKE_HEADLESS_MODE = 'exit_early';
  await assert.rejects(() => B.ghidraRequest('pc-v1', 'info'), /pc-v1: its headless run exited \(code 3[\s\S]*fake: exiting before listening/);
  process.env.FAKE_HEADLESS_MODE = 'script_error';
  await assert.rejects(() => B.ghidraRequest('pc-v1', 'info'), /pc-v1: its GhidraBridge\.java script stopped[\s\S]*REPORT SCRIPT ERROR/);
  delete process.env.FAKE_HEADLESS_MODE;
});

test('the tables and the local config are checked', () => {
  write('bad_projects.tsv', 'image_id\tproject_dir\n');
  assert.throws(() => B.readProjectsTsv(path.join(root, 'bad_projects.tsv')), /header is not image_id/);
  write('dup.toml', 'ghidra_headless = "/bin/sh"\nghidra_headless = "/bin/sh"\n');
  assert.throws(() => B.readGhidraHeadless(path.join(root, 'dup.toml')), /names ghidra_headless more than once/);
  write('none.toml', 'vz_wad = "x"\n');
  assert.throws(() => B.readGhidraHeadless(path.join(root, 'none.toml')), /has no key ghidra_headless/);
  write('notexec.toml', `ghidra_headless = "${path.join(root, 'images.tsv')}"\n`);
  assert.throws(() => B.readGhidraHeadless(path.join(root, 'notexec.toml')), /is not an executable file/);
  assert.throws(() => B.servingImage('pc-zz', new Map()), /image 'pc-zz' is not in/);
});
