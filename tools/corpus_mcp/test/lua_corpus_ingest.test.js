import { test, before, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

// Point every corpus module at a throwaway root before importing them.
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-lua-ingest-'));
process.env.CORPUS_ENV_FILE = path.join(root, 'no.env');
process.env.CORPUS_REPO_ROOT = root;

let luaApiDocs;

async function collect(iter) {
  const out = [];
  for await (const x of iter) out.push(x);
  return out;
}

before(async () => {
  const luaDir = path.join(root, 'tools/wad_simulator/workshop_data/lua/resident');
  const vzDir  = path.join(root, 'tools/wad_simulator/workshop_data/lua/vz');
  fs.mkdirSync(luaDir, { recursive: true });
  fs.mkdirSync(vzDir,  { recursive: true });

  fs.writeFileSync(path.join(luaDir, 'base.lua'), `
function Create(mModule, self)
  return setmetatable(self or {}, {__index = mModule})
end
function IsActive(self)
  return self._nState == 1
end
`);
  fs.writeFileSync(path.join(luaDir, 'child.lua'), `
inherit("base")
import("WifMissionData")
function Activated(self)
  base.Activated(self)
  local tConfig = self:GetConfig()
  if tConfig.bHero then WifMissionData.tMissionData["X"] = {} end
end
`);
  fs.writeFileSync(path.join(vzDir, 'minidata.lua'), `
tThings = {
  Foo = { sName = "Foo", nValue = 1, bEnabled = true },
  Bar = { sName = "Bar", nValue = 2, bEnabled = false },
}
`);

  ({ luaApiDocs } = await import('../src/sources.js'));
});

describe('luaApiDocs generator', () => {
  test('yields one chunk-0 doc per Lua file plus one record-row per record_map record', async () => {
    const docs = await collect(luaApiDocs());
    // 3 files → 3 chunk-0 docs + 2 record rows (Foo, Bar from tThings).
    assert.equal(docs.length, 5);

    const chunk0 = docs.filter((d) => !d.path.includes('#'));
    assert.equal(chunk0.length, 3);
    const names = chunk0.map((d) => d.title).sort();
    assert.deepEqual(names, ['base', 'child', 'minidata']);

    // Every doc carries source, path, title, mtime, fileHash, meta (JSON), chunks (string[]).
    for (const d of docs) {
      assert.equal(d.source, 'lua_api');
      assert.ok(d.path);
      assert.ok(d.title);
      assert.ok(typeof d.mtime === 'number');
      assert.ok(typeof d.fileHash === 'string');
      assert.ok(d.meta);
      assert.ok(Array.isArray(d.chunks));
      assert.equal(d.chunks.length, 1, 'generator emits one chunk per doc; chunking is irrelevant for structured facts');
    }

    // Child's meta round-trips to a ClassAPI with correct inherit chain, imports, and config fields.
    const child = chunk0.find((d) => d.title === 'child');
    const childMeta = JSON.parse(child.meta);
    assert.equal(childMeta.kind, 'class');
    assert.deepEqual(childMeta.inherit_chain, ['child', 'base']);
    assert.deepEqual(childMeta.imports, ['WifMissionData']);
    assert.ok(childMeta.config_fields_read.includes('bHero'));
    const supers = (childMeta.calls_on_super ?? []).map((c) => `${c.module}.${c.method}`);
    assert.ok(supers.includes('base.Activated'));
    const dreads = (childMeta.data_tables_read ?? []).map((d) => `${d.module}.${d.field}`);
    assert.ok(dreads.includes('WifMissionData.tMissionData'));
  });

  test('record_map tables emit per-record docs with scalar fields in meta', async () => {
    const docs = await collect(luaApiDocs());
    const recordDocs = docs.filter((d) => d.path.includes('#tThings.'));
    assert.equal(recordDocs.length, 2);
    const foo = recordDocs.find((d) => d.title === 'Foo');
    assert.ok(foo, 'per-record doc Foo must exist');
    const meta = JSON.parse(foo.meta);
    assert.equal(meta.kind, 'data_record');
    assert.equal(meta.module, 'minidata');
    assert.equal(meta.table, 'tThings');
    assert.equal(meta.key, 'Foo');
    assert.equal(meta.fields.sName, 'Foo');
    assert.equal(meta.fields.nValue, 1);
    assert.equal(meta.fields.bEnabled, true);
  });

  test('chunk-0 summary text includes method names + record keys for FTS to catch', async () => {
    const docs = await collect(luaApiDocs());
    const child = docs.find((d) => d.title === 'child' && !d.path.includes('#'));
    assert.ok(child.chunks[0].includes('Activated'), 'child summary must mention its method so FTS can find it');
    const data = docs.find((d) => d.title === 'minidata' && !d.path.includes('#'));
    assert.ok(data.chunks[0].includes('Foo'));
    assert.ok(data.chunks[0].includes('Bar'));
  });
});
