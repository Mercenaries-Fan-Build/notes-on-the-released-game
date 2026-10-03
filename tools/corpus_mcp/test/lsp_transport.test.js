import { test, before, after, describe } from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// End-to-end drive of the LSP over its real stdio transport (JSON-RPC with Content-Length
// framing). Covers the full capability surface against the real shipped Lua corpus. The pure
// handlers are already covered by lsp_smoke.test.js; this test specifically guards the
// transport layer — the thing that broke when `createConnection` was missing its stream
// arguments.

const here = path.dirname(fileURLToPath(import.meta.url));
const CORPUS_MCP = path.resolve(here, '..');
const REPO = path.resolve(CORPUS_MCP, '..', '..');
const SERVER = path.join(CORPUS_MCP, 'src', 'lsp_server.js');
const ARENA = path.join(REPO, 'tools/wad_simulator/workshop_data/shipments/mercs2-fiona-wave-defense/src/fiodef001_arena.lua');

// Skip transport test if the real arena file is absent (fresh clone without the mod shipment).
const haveArena = fs.existsSync(ARENA);

describe('LSP transport (real stdio)', { skip: !haveArena && 'arena fixture absent' }, () => {
  let child, buf, pending, notifications, nextId, onNotify;

  function send(obj) {
    const body = Buffer.from(JSON.stringify(obj), 'utf8');
    child.stdin.write(`Content-Length: ${body.length}\r\n\r\n`);
    child.stdin.write(body);
  }
  function request(method, params) {
    const id = nextId++;
    send({ jsonrpc: '2.0', id, method, params });
    return new Promise((resolve, reject) => { pending.set(id, { resolve, reject }); });
  }
  function notify(method, params) { send({ jsonrpc: '2.0', method, params }); }

  function waitFor(predicate, timeoutMs = 8000) {
    const existing = notifications.find(predicate);
    if (existing) return Promise.resolve(existing);
    return new Promise((resolve, reject) => {
      const t = setTimeout(() => { onNotify = null; reject(new Error('timeout waiting for notification')); }, timeoutMs);
      onNotify = (msg) => {
        if (predicate(msg)) { clearTimeout(t); onNotify = null; resolve(msg); }
      };
    });
  }

  before(() => {
    buf = Buffer.alloc(0);
    pending = new Map();
    notifications = [];
    nextId = 1;
    onNotify = null;
    child = spawn(process.execPath, [SERVER], {
      cwd: CORPUS_MCP,
      stdio: ['pipe', 'pipe', 'pipe'],
      env: { ...process.env, CORPUS_REPO_ROOT: REPO },
    });
    child.stderr.on('data', () => {}); // swallow the "serving on stdio" line
    child.stdout.on('data', (chunk) => {
      buf = Buffer.concat([buf, chunk]);
      for (;;) {
        const headerEnd = buf.indexOf('\r\n\r\n');
        if (headerEnd === -1) return;
        const header = buf.slice(0, headerEnd).toString('ascii');
        const m = header.match(/Content-Length:\s*(\d+)/i);
        if (!m) throw new Error(`bad LSP header: ${header}`);
        const len = parseInt(m[1], 10);
        const bodyStart = headerEnd + 4;
        if (buf.length < bodyStart + len) return;
        const body = buf.slice(bodyStart, bodyStart + len).toString('utf8');
        buf = buf.slice(bodyStart + len);
        const msg = JSON.parse(body);
        if (msg.id !== undefined && pending.has(msg.id)) {
          const { resolve, reject } = pending.get(msg.id);
          pending.delete(msg.id);
          if (msg.error) reject(new Error(JSON.stringify(msg.error)));
          else resolve(msg.result);
        } else {
          notifications.push(msg);
          if (onNotify) onNotify(msg);
        }
      }
    });
  });

  after(() => {
    try { child.kill(); } catch { /* already gone */ }
  });

  test('initialize advertises the full capability surface', async () => {
    const init = await request('initialize', { processId: process.pid, rootUri: `file:///${REPO.replace(/\\/g, '/')}`, capabilities: {} });
    assert.ok(init.capabilities.hoverProvider);
    assert.ok(init.capabilities.definitionProvider);
    assert.ok(init.capabilities.referencesProvider);
    assert.ok(init.capabilities.workspaceSymbolProvider);
    notify('initialized', {});
  });

  test('didOpen on the real arena publishes 0 diagnostics (shim complete)', async () => {
    const text = fs.readFileSync(ARENA, 'utf8');
    const uri = `file:///${ARENA.replace(/\\/g, '/')}`;
    notify('textDocument/didOpen', { textDocument: { uri, languageId: 'lua', version: 1, text } });
    const diag = await waitFor((m) => m.method === 'textDocument/publishDiagnostics' && m.params.uri === uri);
    assert.equal(diag.params.diagnostics.length, 0);
  });

  test('hover + definition + references on the real corpus', async () => {
    const text = fs.readFileSync(ARENA, 'utf8');
    const uri = `file:///${ARENA.replace(/\\/g, '/')}`;
    const lines = text.split(/\r?\n/);
    const hoverLineIdx = lines.findIndex((l) => /MrxTask\b/.test(l));
    const hoverCol = lines[hoverLineIdx].indexOf('MrxTask') + 2;

    const hover = await request('textDocument/hover', { textDocument: { uri }, position: { line: hoverLineIdx, character: hoverCol } });
    assert.ok(hover?.contents?.value?.includes('MrxTask'));

    const defs = await request('textDocument/definition', { textDocument: { uri }, position: { line: hoverLineIdx, character: hoverCol } });
    assert.ok(Array.isArray(defs) && defs.length === 1);
    assert.match(defs[0].uri, /mrxtask\.lua$/);

    const refLineIdx = lines.findIndex((l) => /CreateChild/.test(l));
    if (refLineIdx >= 0) {
      const refCol = lines[refLineIdx].indexOf('CreateChild') + 2;
      const refs = await request('textDocument/references', { textDocument: { uri }, position: { line: refLineIdx, character: refCol }, context: { includeDeclaration: false } });
      assert.ok(Array.isArray(refs) && refs.length >= 10, `expected ≥10 refs, got ${refs?.length}`);
    }
  });

  test('workspace/symbol query returns real matches', async () => {
    const syms = await request('workspace/symbol', { query: 'MrxTaskObjective' });
    assert.ok(Array.isArray(syms) && syms.length >= 10, `expected ≥10 symbols, got ${syms?.length}`);
  });

  test('a broken shim buffer publishes the missing-method Warning', async () => {
    const text = fs.readFileSync(ARENA, 'utf8');
    const brokenUri = `file:///${REPO.replace(/\\/g, '/')}/scratch_broken.lua`;
    const brokenText = text.replace(/function _FioDef001_ArenaClass\.RefreshPdaDisplay[\s\S]*?end\n/, '-- removed\n');
    notify('textDocument/didOpen', { textDocument: { uri: brokenUri, languageId: 'lua', version: 1, text: brokenText } });
    const diag = await waitFor((m) => m.method === 'textDocument/publishDiagnostics' && m.params.uri === brokenUri);
    const warn = diag.params.diagnostics.find((d) => d.severity === 2 && d.message.includes('_FioDef001_ArenaClass') && d.message.includes('RefreshPdaDisplay'));
    assert.ok(warn, `expected a Warning naming _FioDef001_ArenaClass + RefreshPdaDisplay; got ${JSON.stringify(diag.params.diagnostics)}`);
  });

  test('shutdown + exit closes cleanly', async () => {
    await request('shutdown', null);
    notify('exit', null);
    await new Promise((resolve) => setTimeout(resolve, 200));
  });
});
