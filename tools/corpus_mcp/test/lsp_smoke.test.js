import { test, before, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

// Isolate against a tiny fixture tree before the modules boot.
const repoRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-lsp-'));
process.env.CORPUS_REPO_ROOT = repoRoot;
process.env.CORPUS_ENV_FILE = path.join(repoRoot, 'no.env');

let symbolAt, hoverFor, definitionFor, referencesFor, workspaceSymbol, diagnoseBuffer;
let pathToUri, uriToPath;

before(async () => {
  // Lay down a minimal corpus so search.js's filesystem fallback has something to walk.
  const luaDir = path.join(repoRoot, 'tools/wad_simulator/workshop_data/lua/resident');
  const shipDir = path.join(repoRoot, 'tools/wad_simulator/workshop_data/shipments/mod/src');
  fs.mkdirSync(luaDir, { recursive: true });
  fs.mkdirSync(shipDir, { recursive: true });

  fs.writeFileSync(path.join(luaDir, 'parent.lua'), `
function Activated(self)
  return self._nState
end
function Deactivated(self)
  return self._nState
end
`);
  fs.writeFileSync(path.join(luaDir, 'child.lua'), `
inherit("parent")
function Activated(self)
  parent.Activated(self)
end
`);

  ({ symbolAt, hoverFor, definitionFor, referencesFor, workspaceSymbol, diagnoseBuffer,
     pathToUri, uriToPath } = await import('../src/lsp_server.js'));
});

describe('symbolAt', () => {
  test('resolves bare identifier at the cursor', () => {
    const sym = symbolAt('local oTask = parent', 0, 16);
    assert.equal(sym.kind, 'ident');
    assert.equal(sym.name, 'parent');
    assert.deepEqual(sym.range.start, { line: 0, character: 14 });
    assert.deepEqual(sym.range.end, { line: 0, character: 20 });
  });

  test('resolves X.Y and X:Y member access', () => {
    const dot = symbolAt('  parent.Activated(self)', 0, 10);
    assert.equal(dot.kind, 'member');
    assert.equal(dot.module, 'parent');
    assert.equal(dot.method, 'Activated');

    const colon = symbolAt('  self:GetMissionAncestor()', 0, 12);
    assert.equal(colon.kind, 'member');
    assert.equal(colon.module, 'self');
    assert.equal(colon.method, 'GetMissionAncestor');
  });

  test('returns null in whitespace or past end-of-line', () => {
    assert.equal(symbolAt('   ', 0, 1), null);
    assert.equal(symbolAt('ident', 0, 10), null);
    assert.equal(symbolAt('ident', 5, 0), null);
  });
});

describe('hoverFor', () => {
  test('bare identifier naming a known class returns class metadata', async () => {
    const sym = symbolAt('parent', 0, 2);
    const h = await hoverFor(sym);
    assert.ok(h);
    assert.ok(h.contents.value.includes('class'));
    assert.ok(h.contents.value.includes('parent'));
    assert.ok(h.contents.value.includes('Methods'));
  });

  test('member access naming a defined method returns a code-block signature', async () => {
    const sym = symbolAt('parent.Activated(self)', 0, 10);
    const h = await hoverFor(sym);
    assert.ok(h);
    assert.match(h.contents.value, /function parent:Activated\(self, \.\.\.\)/);
  });

  test('member access on a known class but unknown method returns a not-defined marker', async () => {
    const sym = symbolAt('parent.Nonexistent(self)', 0, 10);
    const h = await hoverFor(sym);
    assert.ok(h.contents.value.includes('not defined'));
  });

  test('unknown bare identifier returns null (no hover)', async () => {
    const sym = symbolAt('xyzzy', 0, 1);
    const h = await hoverFor(sym);
    assert.equal(h, null);
  });
});

describe('definitionFor', () => {
  test('bare identifier naming a class resolves to the source path', async () => {
    const sym = symbolAt('parent', 0, 2);
    const locs = await definitionFor(sym, repoRoot);
    assert.equal(locs.length, 1);
    assert.ok(locs[0].uri.endsWith('parent.lua'));
    assert.equal(locs[0].range.start.line, 0);
  });

  test('member access resolves to the method line', async () => {
    const sym = symbolAt('parent.Activated(self)', 0, 10);
    const locs = await definitionFor(sym, repoRoot);
    assert.equal(locs.length, 1);
    assert.ok(locs[0].uri.endsWith('parent.lua'));
    assert.equal(locs[0].range.start.line, 1, 'Activated is defined at line 2 (0-indexed 1)');
  });
});

describe('referencesFor', () => {
  test('member reference finds call sites in sibling files', async () => {
    const sym = symbolAt('parent.Activated(self)', 0, 10);
    const locs = await referencesFor(sym);
    assert.ok(locs.length >= 1, 'child.lua calls parent.Activated so at least one hit');
    assert.ok(locs.some((l) => l.uri.endsWith('child.lua')));
  });
});

describe('workspaceSymbol', () => {
  test('matches by substring, case-insensitive', async () => {
    const parent = await workspaceSymbol('PARENT', repoRoot);
    assert.ok(parent.find((s) => s.name === 'parent'));
    const all = await workspaceSymbol('', repoRoot);
    assert.ok(all.length >= 2, 'both parent and child artifacts present');
  });
});

describe('diagnoseBuffer', () => {
  test('clean buffer produces no diagnostics', async () => {
    const diag = await diagnoseBuffer('file:///x.lua', 'local a = 1\n');
    assert.equal(diag.length, 0);
  });

  test('syntax error produces one Error diagnostic', async () => {
    const diag = await diagnoseBuffer('file:///x.lua', 'local a = \n');
    assert.equal(diag.length, 1);
    assert.equal(diag[0].severity, 1);
    assert.match(diag[0].message, /Lua parse error/);
  });

  test('table-acts-as-class with partial duck-typed contract surfaces missing methods', async () => {
    const buf = `
_ArenaClass = {}
function _ArenaClass.GetMissionId(self) return 1 end
function _ArenaClass.GetName(self) return "x" end
-- missing: RefreshPdaDisplay
`;
    const diag = await diagnoseBuffer('file:///x.lua', buf);
    assert.equal(diag.length, 1);
    assert.equal(diag[0].severity, 2);
    assert.match(diag[0].message, /_ArenaClass/);
    assert.match(diag[0].message, /mission-ancestor/);
    assert.match(diag[0].message, /RefreshPdaDisplay/);
  });

  test('empty-receiver shim (zero contract methods) does NOT warn — not an intended shim', async () => {
    const buf = `
_Unrelated = {}
function _Unrelated.foo(self) end
`;
    const diag = await diagnoseBuffer('file:///x.lua', buf);
    assert.equal(diag.length, 0);
  });

  test('weak match (one of three required methods) does NOT warn', async () => {
    // A GUI widget class that declares GetName but has nothing to do with mission ancestors.
    // Without the threshold, this would wrongly fire the mission-ancestor shim warning — the
    // corpus walk surfaced exactly this false positive on `Widget` in mrxguibase.lua.
    const buf = `
Widget = {}
function Widget:GetName() return self.name end
function Widget:SetName(n) self.name = n end
function Widget:SetVisible(b) end
`;
    const diag = await diagnoseBuffer('file:///x.lua', buf);
    assert.equal(diag.length, 0, 'one-of-three matches is coincidence, not an intended shim');
  });
});

describe('URI helpers', () => {
  test('pathToUri + uriToPath round-trips a windows-style absolute path', () => {
    const abs = 'C:\\Users\\Shadow\\Desktop\\file.lua';
    const uri = pathToUri(abs);
    assert.match(uri, /^file:\/\/\/C:\//);
    const back = uriToPath(uri);
    assert.equal(back.toLowerCase(), abs.toLowerCase());
  });
});
