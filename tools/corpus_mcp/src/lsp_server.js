#!/usr/bin/env node
/**
 * LSP server over the corpus index.
 *
 * Any LSP-aware editor (VSCode, Neovim, Zed) can connect for hover / goto-definition /
 * find-references / workspace-symbol over the whole shipped Lua corpus — a better-than-sumneko
 * experience for Mercs2 code because the index knows about `inherit` chains and cross-file call
 * sites, not just the files currently open.
 *
 * Design: the transport (stdio JSON-RPC) is a thin shell around pure handlers in this file.
 * Everything a request needs — a buffer and a position — resolves to a symbol via `symbolAt`,
 * then delegates to search.js. The handlers are deliberately exported so tests drive them
 * without any transport layer at all.
 */
import fs from 'node:fs';
import path from 'node:path';
import * as luaparse from 'luaparse';
import { createConnection, ProposedFeatures, TextDocuments, TextDocumentSyncKind } from 'vscode-languageserver/node.js';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { luaApi, luaXref, clearCaches } from './search.js';
import { allArtifacts } from './lua_analyzer.js';

const LUA_ROOTS = [
  'tools/wad_simulator/workshop_data/lua',
  'tools/wad_simulator/workshop_data/shipments',
];

function resolveRepoRoot() {
  if (process.env.CORPUS_REPO_ROOT) return path.resolve(process.env.CORPUS_REPO_ROOT);
  const here = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([a-zA-Z]:)/, '$1'));
  return path.resolve(here, '..', '..', '..');
}

// --- pure helpers (tested directly) ----------------------------------------

/**
 * Resolve the identifier / member chain at `(line, character)` in `text`. Returns:
 *   { kind: "member", module, method, range } for X.Y / X:Y references
 *   { kind: "ident",  name, range }           for a single identifier
 *   null if nothing is there.
 *
 * Regex-only. The LSP must respond to every keystroke; parsing with luaparse on each hover
 * is too slow and would reject half-typed buffers. The regex only has to find the surrounding
 * token — the semantic lookup happens via the pre-indexed corpus.
 */
export function symbolAt(text, line, character) {
  const lines = text.split(/\r?\n/);
  if (line < 0 || line >= lines.length) return null;
  const src = lines[line];
  // A position strictly past end-of-line (not on EOL) is nowhere — common when the editor sends a
  // click past the text; return null rather than searching leftward for whatever happens to be
  // closest.
  if (character > src.length) return null;
  const ident = /[A-Za-z0-9_]/;
  let start = character;
  while (start > 0 && start - 1 < src.length && ident.test(src[start - 1])) start -= 1;
  let end = character;
  while (end < src.length && ident.test(src[end])) end += 1;
  if (start === end) return null;
  const name = src.slice(start, end);
  if (!/^[A-Za-z_]/.test(name)) return null;

  // Is the token preceded by `.` or `:` and another identifier? Then it's a member access.
  let i = start - 1;
  if (i >= 0 && (src[i] === '.' || src[i] === ':')) {
    i -= 1;
    const modEnd = i + 1;
    while (i >= 0 && ident.test(src[i])) i -= 1;
    const module = src.slice(i + 1, modEnd);
    if (module && /^[A-Za-z_]/.test(module)) {
      return {
        kind: 'member',
        module,
        method: name,
        range: { start: { line, character: start }, end: { line, character: end } },
        moduleRange: { start: { line, character: i + 1 }, end: { line, character: modEnd } },
      };
    }
  }
  return {
    kind: 'ident',
    name,
    range: { start: { line, character: start }, end: { line, character: end } },
  };
}

/**
 * Format a hover for a Lua symbol. Returns the LSP Hover payload or null if nothing matches.
 */
export async function hoverFor(symbol) {
  if (!symbol) return null;
  if (symbol.kind === 'member') {
    const art = await luaApi({ name: symbol.module, resolve_chain: true }).catch(() => null);
    if (!art || art.error) return null;
    const methods = [...(art.methods_defined ?? []), ...(art.inherited_methods ?? [])];
    const m = methods.find((x) => x.name === symbol.method);
    if (!m) return markdown(`**${symbol.module}.${symbol.method}** — not defined on \`${symbol.module}\``);
    const owner = m.inherited_from ?? symbol.module;
    return markdown([
      '```lua',
      `function ${owner}:${m.name}(self, ...)`,
      '```',
      m.inherited_from ? `_Inherited from \`${m.inherited_from}\`._` : '',
      art.inherit_chain ? `_Inherit chain: ${art.inherit_chain.join(' → ')}_` : '',
    ].filter(Boolean).join('\n'));
  }
  // Bare identifier: look it up as a class/data-module name.
  const art = await luaApi({ name: symbol.name, resolve_chain: true }).catch(() => null);
  if (!art || art.error) return null;
  if (art.kind === 'class') {
    return markdown([
      `**class \`${art.class}\`**`,
      art.inherit_chain?.length ? `Inherit chain: ${art.inherit_chain.join(' → ')}` : '',
      art.imports?.length ? `Imports: ${art.imports.join(', ')}` : '',
      `Methods: ${(art.methods_defined ?? []).length}` +
        (art.inherited_methods?.length ? ` (+${art.inherited_methods.length} inherited)` : ''),
    ].filter(Boolean).join('\n\n'));
  }
  if (art.kind === 'data') {
    const tables = (art.tables ?? []).filter((t) => t.shape).map((t) => `\`${t.name}\` (${t.shape})`).join(', ');
    return markdown([`**data module \`${art.module}\`**`, tables && `Tables: ${tables}`].filter(Boolean).join('\n\n'));
  }
  return null;
}

/**
 * Resolve a symbol to a `Location[]` for goto-definition.
 */
export async function definitionFor(symbol, repoRoot) {
  if (!symbol) return [];
  const target = symbol.kind === 'member' ? symbol.module : symbol.name;
  const art = await luaApi({ name: target, resolve_chain: true }).catch(() => null);
  if (!art || art.error) return [];
  if (symbol.kind === 'member') {
    const methods = [...(art.methods_defined ?? []), ...(art.inherited_methods ?? [])];
    const m = methods.find((x) => x.name === symbol.method);
    if (!m) return [];
    const sourcePath = m.inherited_from
      ? await resolveClassPath(m.inherited_from, repoRoot)
      : art.source_path;
    if (!sourcePath) return [];
    return [locationOf(sourcePath, (m.line ?? 1) - 1)];
  }
  return [locationOf(art.source_path, 0)];
}

/**
 * Resolve references for a symbol to a `Location[]`.
 */
export async function referencesFor(symbol) {
  if (!symbol) return [];
  const query = symbol.kind === 'member' ? `${symbol.module}.${symbol.method}` : symbol.name;
  const res = await luaXref({ symbol: query, limit: 500 }).catch(() => null);
  if (!res?.hits) return [];
  const locations = [];
  for (const hit of res.hits) {
    if (!hit.source_path || typeof hit.line !== 'number') continue;
    locations.push(locationOf(hit.source_path, hit.line - 1));
  }
  return locations;
}

/**
 * Workspace-symbol: every class / data-module whose name contains `query` (case-insensitive).
 */
export async function workspaceSymbol(query, repoRoot) {
  const q = (query ?? '').toLowerCase();
  const results = [];
  for (const rel of LUA_ROOTS) {
    const abs = path.resolve(repoRoot, rel);
    if (!fs.existsSync(abs)) continue;
    const batch = allArtifacts(abs);
    for (const art of batch.values()) {
      const name = art.class ?? art.module;
      if (!name) continue;
      if (q && !name.toLowerCase().includes(q)) continue;
      results.push({
        name,
        kind: 5, // Class
        location: locationOf(art.source_path, 0),
      });
      if (results.length > 500) return results;
    }
  }
  return results;
}

/**
 * Compile-time diagnostics for a buffer. Parses with luaparse; a syntax error becomes one
 * diagnostic. For a table-acts-as-class pattern (`T = {}` + `function T.M(self)` definitions)
 * that looks intended as a shim for a known duck-typed contract, surface the missing methods
 * as a warning — the "which methods is my shim missing?" lint.
 */
export async function diagnoseBuffer(uri, text, contracts = DEFAULT_DUCK_CONTRACTS) {
  const diagnostics = [];
  try {
    luaparse.parse(text, { locations: true, scope: false });
  } catch (e) {
    diagnostics.push({
      severity: 1, // Error
      range: pointRange(e.line ? e.line - 1 : 0, e.column ?? 0),
      message: `Lua parse error: ${e.message}`,
      source: 'corpus-mcp',
    });
    return diagnostics;
  }
  // Find every `function T.M(self)` form and bucket methods by receiver.
  const buckets = new Map();
  const defRE = /function\s+([A-Za-z_][A-Za-z0-9_]*)\s*[.:]\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(/g;
  let m;
  while ((m = defRE.exec(text)) !== null) {
    const [, receiver, method] = m;
    if (!buckets.has(receiver)) buckets.set(receiver, { methods: new Set(), line: offsetToLine(text, m.index) });
    buckets.get(receiver).methods.add(method);
  }
  // Compare each receiver against the duck contracts. A match is only strong enough to be worth
  // flagging when the receiver declares most of the contract — matching one method out of three
  // is coincidence (every class with a `GetName` is not an intended mission-ancestor shim).
  // Require at most one method missing: that is the "nearly satisfies the contract" shape where a
  // typo or oversight is likely, which is where this lint earns its keep.
  for (const [receiver, info] of buckets) {
    for (const [contractName, required] of Object.entries(contracts)) {
      const missing = required.filter((name) => !info.methods.has(name));
      if (missing.length > 0 && missing.length <= Math.max(1, required.length - 2)) {
        diagnostics.push({
          severity: 2, // Warning
          range: pointRange(info.line, 0),
          message: `\`${receiver}\` looks like a ${contractName} shim but is missing: ${missing.join(', ')}`,
          source: 'corpus-mcp',
        });
      }
    }
  }
  return diagnostics;
}

/**
 * Duck-typed contracts to lint against. Each key is a label for the contract; each value is the
 * required method set. Driven by what shipped engine primitives actually call on their duck-typed
 * parents.
 */
export const DEFAULT_DUCK_CONTRACTS = {
  'mission-ancestor': ['GetMissionId', 'GetName', 'RefreshPdaDisplay'],
};

// --- transport helpers -----------------------------------------------------

function markdown(value) {
  return { contents: { kind: 'markdown', value } };
}

function locationOf(absPath, line) {
  const uri = pathToUri(absPath);
  return { uri, range: pointRange(line, 0) };
}

function pointRange(line, character) {
  return { start: { line, character }, end: { line, character: character + 1 } };
}

function offsetToLine(text, offset) {
  let line = 0;
  for (let i = 0; i < offset; i += 1) if (text[i] === '\n') line += 1;
  return line;
}

export function pathToUri(absPath) {
  const norm = absPath.replace(/\\/g, '/');
  return norm.startsWith('/') ? `file://${norm}` : `file:///${norm}`;
}

export function uriToPath(uri) {
  const p = uri.replace(/^file:\/\//, '');
  if (/^\/[A-Za-z]:\//.test(p)) return p.slice(1).replace(/\//g, path.sep);
  return p.replace(/\//g, path.sep);
}

async function resolveClassPath(className, repoRoot) {
  for (const rel of LUA_ROOTS) {
    const abs = path.resolve(repoRoot, rel);
    if (!fs.existsSync(abs)) continue;
    const batch = allArtifacts(abs);
    const hit = batch.get(className) ?? batch.get(className.toLowerCase());
    if (hit) return hit.source_path;
  }
  return null;
}

// --- transport (only runs when invoked as the entrypoint) ------------------

function isEntrypoint() {
  if (!process.argv[1]) return false;
  const entry = path.resolve(process.argv[1]);
  const self = path.resolve(new URL(import.meta.url).pathname.replace(/^\/([a-zA-Z]:)/, '$1'));
  return entry === self;
}

if (isEntrypoint()) {
  const connection = createConnection(ProposedFeatures.all, process.stdin, process.stdout);
  const documents = new TextDocuments(TextDocument);
  const repoRoot = resolveRepoRoot();

  connection.onInitialize(() => ({
    capabilities: {
      textDocumentSync: TextDocumentSyncKind.Incremental,
      hoverProvider: true,
      definitionProvider: true,
      referencesProvider: true,
      workspaceSymbolProvider: true,
    },
  }));

  connection.onHover(async ({ textDocument, position }) => {
    const doc = documents.get(textDocument.uri);
    if (!doc) return null;
    const sym = symbolAt(doc.getText(), position.line, position.character);
    return (await hoverFor(sym)) ?? null;
  });

  connection.onDefinition(async ({ textDocument, position }) => {
    const doc = documents.get(textDocument.uri);
    if (!doc) return [];
    return definitionFor(symbolAt(doc.getText(), position.line, position.character), repoRoot);
  });

  connection.onReferences(async ({ textDocument, position }) => {
    const doc = documents.get(textDocument.uri);
    if (!doc) return [];
    return referencesFor(symbolAt(doc.getText(), position.line, position.character));
  });

  connection.onWorkspaceSymbol(({ query }) => workspaceSymbol(query, repoRoot));

  documents.onDidChangeContent(async (change) => {
    const diagnostics = await diagnoseBuffer(change.document.uri, change.document.getText());
    connection.sendDiagnostics({ uri: change.document.uri, diagnostics });
  });

  documents.listen(connection);
  connection.listen();
  // The index caches are populated lazily on first query; a transcript reload wipes them so the
  // LSP picks up newly-ingested facts without a server restart.
  connection.onRequest('corpus/clearCaches', () => { clearCaches(); return { ok: true }; });
  console.error('[corpus-lsp] serving on stdio');
}
