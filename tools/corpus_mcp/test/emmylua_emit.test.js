import { test, before, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

// Isolate the emitter against a tiny fixture tree.
const repoRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-emit-'));
process.env.CORPUS_REPO_ROOT = repoRoot;
process.env.CORPUS_ENV_FILE = path.join(repoRoot, 'no.env');

let emitAll, writeLuarc;

before(async () => {
  const luaDir = path.join(repoRoot, 'tools/wad_simulator/workshop_data/lua/resident');
  const dataDir = path.join(repoRoot, 'tools/wad_simulator/workshop_data/lua/vz');
  fs.mkdirSync(luaDir, { recursive: true });
  fs.mkdirSync(dataDir, { recursive: true });

  // Base class.
  fs.writeFileSync(path.join(luaDir, 'base.lua'), `
function Activated(self)
  return self._nState
end
function GetName(self)
  return self._sName
end
`);
  // Child class with inherit + imports + config reads.
  fs.writeFileSync(path.join(luaDir, 'child.lua'), `
inherit("base")
import("ShipData")
function Activated(self)
  base.Activated(self)
  local tConfig = self:GetConfig()
  if tConfig.bHero then
    local oMission = self:GetMissionAncestor()
    oMission:GetMissionId()
  end
end
`);
  // Data module with a record_map + a scalar.
  fs.writeFileSync(path.join(dataDir, 'shipdata.lua'), `
tShipments = {
  Alpha = { sName = "Alpha", nTier = 1, bEnabled = true },
  Beta  = { sName = "Beta",  nTier = 2, bEnabled = false },
}
nShipTotal = 2
`);

  ({ emitAll, writeLuarc } = await import('../src/emmylua_emit.js'));
});

describe('emitAll', () => {
  test('writes one .lua stub per class + per data module and reports counts', () => {
    const outDir = path.join(repoRoot, 'tools/emmylua_stubs/mercs2');
    const result = emitAll({ outDir });
    assert.equal(result.outDir, outDir);
    assert.equal(result.classes, 2, 'base + child are both classes');
    assert.equal(result.dataModules, 1);
    assert.equal(result.recordShapes, 1, 'one record_map table in shipdata');

    const scriptDir = path.join(outDir, 'script');
    assert.ok(fs.existsSync(path.join(scriptDir, 'base.lua')));
    assert.ok(fs.existsSync(path.join(scriptDir, 'child.lua')));
    assert.ok(fs.existsSync(path.join(scriptDir, 'shipdata.lua')));
  });

  test('class stub carries ---@class + inherit + ---@field for config + method signatures', () => {
    const stub = fs.readFileSync(
      path.join(repoRoot, 'tools/emmylua_stubs/mercs2/script/child.lua'),
      'utf8',
    );
    assert.match(stub, /---@class child : base/);
    assert.match(stub, /---@field bHero boolean/);
    assert.match(stub, /function child:Activated\(\.\.\.\) end/);
    assert.ok(!stub.includes('FioDef'), 'stubs must not carry project-specific commentary');
    assert.ok(!stub.includes('Tier'), 'stubs must not carry plan tier labels');
  });

  test('data stub carries one @class per record_map + typed @field for every union key', () => {
    const stub = fs.readFileSync(
      path.join(repoRoot, 'tools/emmylua_stubs/mercs2/script/shipdata.lua'),
      'utf8',
    );
    assert.match(stub, /---@class shipdata\.tShipmentsRecord/);
    assert.match(stub, /---@field sName.*string/);
    assert.match(stub, /---@field nTier.*number/);
    assert.match(stub, /---@field bEnabled.*boolean/);
    assert.match(stub, /---@field tShipments table<string, shipdata\.tShipmentsRecord>/);
    assert.match(stub, /---@field nShipTotal number/, 'scalar fields infer type from Hungarian prefix');
  });

  test('globals are the artifact names + every imported module', () => {
    const outDir = path.join(repoRoot, 'tools/emmylua_stubs/mercs2');
    const result = emitAll({ outDir });
    assert.ok(result.globals.includes('base'));
    assert.ok(result.globals.includes('child'));
    assert.ok(result.globals.includes('ShipData'), 'imported-but-unstubbed modules land in globals too');
  });
});

describe('writeLuarc', () => {
  test('writes .luarc.json at repo root with library paths + globals, overwrites previous', () => {
    const emit = emitAll({});
    const r = writeLuarc({ stubRoot: emit.outDir, globals: emit.globals });
    assert.equal(r.path, path.join(repoRoot, '.luarc.json'));
    const parsed = JSON.parse(fs.readFileSync(r.path, 'utf8'));
    assert.equal(parsed.runtime.version, 'Lua 5.1');
    assert.deepEqual(parsed.workspace.library, [
      'tools/emmylua_stubs/mercs2/engine',
      'tools/emmylua_stubs/mercs2/script',
    ]);
    assert.ok(parsed.diagnostics.globals.includes('ShipData'));
  });
});
