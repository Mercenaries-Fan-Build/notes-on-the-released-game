import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { analyzeFile, resolveInheritChain, allArtifacts, inferType, HUNGARIAN } from '../src/lua_analyzer.js';

// Tiny fixtures written to a tmpdir so these tests don't depend on the shipped Lua corpus.
// Covers each discriminator path (class, data, shim-table-in-data-file, inherit-chain walk,
// config-alias field reads, super-call pattern, record_map schema inference).

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'lua-analyzer-'));
function fixture(name, body) {
  const p = path.join(tmp, name);
  fs.writeFileSync(p, body);
  return p;
}

describe('lua_analyzer — class mode', () => {
  test('inherit() + top-level function + self:X() + config-alias field reads', () => {
    const f = fixture('obj.lua', `
inherit("Base")
import("MrxUtil")

function Activated(self, tArgs)
  local tConfig = self:GetConfig()
  self:_SetState("active")
  if tConfig.bHero then
    return tConfig.vTarget
  end
end
`);
    const api = analyzeFile(f);
    assert.equal(api.kind, 'class');
    assert.equal(api.class, 'obj');
    assert.deepEqual(api.imports, ['MrxUtil']);
    assert.deepEqual(api.inherit_chain, ['obj', 'Base']);
    assert.equal(api.methods_defined.length, 1);
    assert.equal(api.methods_defined[0].name, 'Activated');
    const selfCalls = api.calls_on_self.map((c) => c.method);
    assert.ok(selfCalls.includes('GetConfig'), 'calls_on_self must include GetConfig');
    assert.ok(selfCalls.includes('_SetState'), 'calls_on_self must include _SetState');
    assert.ok(api.config_fields_read.includes('bHero'));
    assert.ok(api.config_fields_read.includes('vTarget'));
  });

  test('<Module>.X(self, ...) is classified as super call only when Module is in inherit chain', () => {
    const f = fixture('child.lua', `
inherit("Parent")
function Activated(self)
  Parent.Activated(self)
  Unrelated.DoThing(self)
end
`);
    const api = analyzeFile(f);
    const supers = api.calls_on_super.map((c) => `${c.module}.${c.method}`);
    assert.ok(supers.includes('Parent.Activated'));
    assert.ok(!supers.includes('Unrelated.DoThing'), 'super detection must require module in inherit chain');
  });

  test('self:GetMissionAncestor():X() flows into calls_on_mission_ancestor', () => {
    const f = fixture('mamma.lua', `
inherit("Base")
function Thing(self)
  self:GetMissionAncestor():RefreshPdaDisplay()
  local oMission = self:GetMissionAncestor()
  oMission:GetMissionId()
end
`);
    const api = analyzeFile(f);
    const methods = api.calls_on_mission_ancestor.map((c) => c.method);
    assert.ok(methods.includes('RefreshPdaDisplay'));
    assert.ok(methods.includes('GetMissionId'));
  });

  test('top-level function without inherit still classifies as class (base-class pattern)', () => {
    // mrxtask.lua in the shipped corpus has no inherit() but IS a class (defines Create).
    const f = fixture('base.lua', `
import("Something")
function Create(mModule, self)
  return setmetatable(self or {}, {__index = mModule})
end
function IsActive(self)
  return self._nState == 1
end
`);
    const api = analyzeFile(f);
    assert.equal(api.kind, 'class', 'file with top-level functions must classify as class even without inherit()');
    assert.equal(api.methods_defined.length, 2);
  });
});

describe('lua_analyzer — data mode', () => {
  test('record_map table with schema union + required/count metadata', () => {
    const f = fixture('data.lua', `
tStuff = {
  Foo = { sName = "Foo", nValue = 1, bEnabled = true },
  Bar = { sName = "Bar", nValue = 2 },
  Baz = { sName = "Baz", bEnabled = false, tLayers = { "x", "y" } },
}
`);
    const api = analyzeFile(f);
    assert.equal(api.kind, 'data');
    const t = api.tables.find((t) => t.name === 'tStuff');
    assert.ok(t, 'tStuff table must be present');
    assert.equal(t.shape, 'record_map');
    assert.equal(t.record_count, 3);
    assert.deepEqual(Object.keys(t.record_schema).sort(), ['bEnabled', 'nValue', 'sName', 'tLayers']);
    assert.equal(t.record_schema.sName.count, 3);
    assert.equal(t.record_schema.sName.required, true);
    assert.equal(t.record_schema.nValue.required, false, 'nValue is absent from Baz, so not required');
    assert.equal(t.record_schema.sName.type, 'string');
    assert.equal(t.record_schema.nValue.type, 'number');
    assert.equal(t.record_schema.bEnabled.type, 'boolean');
    assert.equal(t.record_schema.tLayers.type, 'table');
  });

  test('ordered_list table (ipairs-shaped) + scalar module globals', () => {
    const f = fixture('lists.lua', `
_tStarters = { "AllStarter0", "ChiStarter0", "GurStarter0" }
nInGameCash = 0
`);
    const api = analyzeFile(f);
    assert.equal(api.kind, 'data');
    const t = api.tables.find((t) => t.name === '_tStarters');
    assert.ok(t);
    assert.equal(t.shape, 'ordered_list');
    assert.equal(t.record_count, 3);
    const scalar = api.tables.find((t) => t.name === 'nInGameCash');
    assert.ok(scalar);
    assert.equal(scalar.shape, 'scalar');
    assert.equal(scalar.value, 0);
  });

  test('data-mode file with namespaced function declarations collects methods under their receiver', () => {
    // Table-acts-as-class pattern: declare an object and attach methods via function T.M(self).
    const f = fixture('shim.lua', `
_FioDef001_ArenaClass = _FioDef001_ArenaClass or {}
function _FioDef001_ArenaClass.GetMissionId(self)     return "FioDef001" end
function _FioDef001_ArenaClass.GetName(self)          return "FioDef001Arena" end
function _FioDef001_ArenaClass.RefreshPdaDisplay(self) end
`);
    const api = analyzeFile(f);
    assert.equal(api.kind, 'class', 'module-scope function defs mean class-mode regardless of inherit');
    const shim = api.methods_defined
      .filter((m) => m.on === '_FioDef001_ArenaClass')
      .map((m) => m.name);
    assert.deepEqual(shim.sort(), ['GetMissionId', 'GetName', 'RefreshPdaDisplay']);
  });
});

describe('lua_analyzer — inherit chain walk', () => {
  test('resolveInheritChain follows parents through the loader and surfaces inherited_methods', () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'lua-chain-'));
    fs.writeFileSync(path.join(dir, 'base.lua'), `
function BaseMethod(self) end
function Create(self) end
`);
    fs.writeFileSync(path.join(dir, 'mid.lua'), `
inherit("base")
function MidMethod(self) end
`);
    fs.writeFileSync(path.join(dir, 'top.lua'), `
inherit("mid")
function TopMethod(self) end
`);
    const cache = allArtifacts(dir);
    const top = cache.get('top');
    assert.ok(top);
    const resolved = resolveInheritChain(top, (parent) => cache.get(parent) ?? cache.get(parent.toLowerCase()) ?? null);
    assert.deepEqual(resolved.inherit_chain, ['top', 'mid', 'base']);
    const inheritedNames = resolved.inherited_methods.map((m) => m.name).sort();
    assert.deepEqual(inheritedNames, ['BaseMethod', 'Create', 'MidMethod'].sort());
  });
});

describe('lua_analyzer — type inference', () => {
  test('Hungarian prefix fallback when the literal is not known', () => {
    assert.equal(inferType('bEnabled', null), 'boolean');
    assert.equal(inferType('nValue', null), 'number');
    assert.equal(inferType('sName', null), 'string');
    assert.equal(inferType('tLayers', null), 'table');
    assert.equal(inferType('fCallback', null), 'function');
    assert.equal(inferType('uGuid', null), 'userdata');
    assert.equal(inferType('oTask', null), HUNGARIAN.o);
    assert.equal(inferType('nothingSpecial', null), 'any');
  });

  test('literal type wins over Hungarian prefix', () => {
    assert.equal(inferType('bHero', { type: 'StringLiteral' }), 'string');
    assert.equal(inferType('xUnknown', { type: 'BooleanLiteral' }), 'boolean');
  });
});

// --- end-to-end: against the real shipped corpus if available ----------
// These tests only run when the Mercs2 Lua tree is present. They assert the real-corpus answers
// hold — "class X requires method M on its parent" and "the mod's shim table declares M" — so a
// typo-level regression in the shim lands as a failing test, not a game-boot symptom.

const SHIPPED_LUA = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([a-zA-Z]:)/, '$1')), '..', '..', 'wad_simulator', 'workshop_data', 'lua');
const ARENA_SRC = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([a-zA-Z]:)/, '$1')), '..', '..', 'wad_simulator', 'workshop_data', 'shipments', 'mercs2-fiona-wave-defense', 'src', 'fiodef001_arena.lua');

const haveShipped = fs.existsSync(path.join(SHIPPED_LUA, 'resident', 'mrxtaskobjective.lua'));

describe('lua_analyzer — shipped-corpus integration', { skip: !haveShipped }, () => {
  test('MrxTaskObjective calls_on_mission_ancestor is exactly {GetMissionId, RefreshPdaDisplay, IsContract}', () => {
    const api = analyzeFile(path.join(SHIPPED_LUA, 'resident', 'mrxtaskobjective.lua'));
    assert.equal(api.kind, 'class');
    const methods = new Set(api.calls_on_mission_ancestor.map((c) => c.method));
    assert.ok(methods.has('GetMissionId'));
    assert.ok(methods.has('RefreshPdaDisplay'));
    assert.ok(methods.has('IsContract'));
    assert.equal(methods.size, 3);
  });

  test('FioDef001 arena shim covers GetMissionId + RefreshPdaDisplay, is missing IsContract', { skip: !fs.existsSync(ARENA_SRC) }, () => {
    const obj = analyzeFile(path.join(SHIPPED_LUA, 'resident', 'mrxtaskobjective.lua'));
    const arena = analyzeFile(ARENA_SRC);
    const required = new Set(obj.calls_on_mission_ancestor.map((c) => c.method));
    const shim = new Set(
      arena.methods_defined
        .filter((m) => m.on === '_FioDef001_ArenaClass')
        .map((m) => m.name),
    );
    const covered = [...required].filter((m) => shim.has(m)).sort();
    const missing = [...required].filter((m) => !shim.has(m));
    assert.deepEqual(covered, ['GetMissionId', 'RefreshPdaDisplay']);
    assert.deepEqual(missing, ['IsContract']);
  });

  test('WifMissionData — class-mode (helper fns at top) with a record_map tMissionData table facet', () => {
    // wifmissiondata.lua has both top-level helper functions (Init, IsMissionAContract, ...) AND
    // the massive tMissionData registry. The classifier picks class because of the methods;
    // the data facet comes through on the `tables` field, not as a separate kind.
    const api = analyzeFile(path.join(SHIPPED_LUA, 'vz', 'wifmissiondata.lua'));
    assert.equal(api.kind, 'class');
    assert.ok(api.methods_defined.length > 0, 'wifmissiondata declares helper methods');
    const t = api.tables.find((t) => t.name === 'tMissionData');
    assert.ok(t, 'wifmissiondata.lua must expose a tMissionData table');
    assert.equal(t.shape, 'record_map');
    assert.ok(t.record_count >= 60);
    assert.equal(t.record_schema.sModuleName.required, true);
    assert.equal(t.record_schema.sFactionId.required, true);
  });

  test('xQ!L.lua is not skipped (non-ASCII filename) and surfaces its data facet', { skip: !fs.existsSync(path.join(SHIPPED_LUA, 'vz', 'xQ!L.lua')) }, () => {
    const api = analyzeFile(path.join(SHIPPED_LUA, 'vz', 'xQ!L.lua'));
    // The file has helper functions AND top-level data tables; whichever kind it classifies as,
    // its _tStaticLayers table must be captured (the correctness condition we care about —
    // "don't skip data tables"). The non-ASCII `!` filename is a filesystem concern, not a
    // parse concern; getting to this assertion at all is the test.
    assert.notEqual(api.kind, 'parse_error', 'xQ!L.lua must parse cleanly');
    const layers = api.tables?.find((t) => t.name === '_tStaticLayers');
    assert.ok(layers, 'xQ!L.lua must surface _tStaticLayers in its tables facet');
  });
});
