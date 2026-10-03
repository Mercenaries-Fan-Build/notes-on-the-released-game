/**
 * Lua static analyzer for the Mercs2 scripting corpus.
 *
 * Public API:
 *   analyzeFile(absPath)           -> ClassAPI | DataAPI
 *   resolveInheritChain(cls, load) -> ClassAPI with chain + inherited sites filled
 *   allArtifacts(rootDir)          -> Map<name, ClassAPI | DataAPI>
 *
 * Design:
 *   Classify by first top-level `inherit(...)` call. `kind:"class"` extracts methods, calls,
 *   config-field access and parent-contract probes. `kind:"data"` extracts top-level table
 *   assignments with per-record schema inference. Both share the same envelope so downstream
 *   caches can route by kind.
 */
import fs from 'node:fs';
import path from 'node:path';
import luaparse from 'luaparse';

// --- utility ------------------------------------------------------------

function unquote(raw) {
  // luaparse StringLiteral.value is null by default; the `raw` field has the quoted literal.
  if (!raw) return null;
  const q = raw[0];
  if ((q === '"' || q === "'") && raw[raw.length - 1] === q) return raw.slice(1, -1);
  if (raw.startsWith('[[') && raw.endsWith(']]')) return raw.slice(2, -2);
  return raw;
}

function strValue(node) {
  if (!node) return null;
  if (node.type === 'StringLiteral') return unquote(node.raw);
  return null;
}

function identName(node) {
  if (!node) return null;
  if (node.type === 'Identifier') return node.name;
  if (node.type === 'MemberExpression' && node.base && node.identifier) {
    const base = identName(node.base);
    return base ? `${base}.${node.identifier.name}` : node.identifier.name;
  }
  return null;
}

function lineOf(node) {
  return node?.loc?.start?.line ?? null;
}

// Hungarian-prefix -> EmmyLua type hint. Shared with the stub emitter.
export const HUNGARIAN = {
  b: 'boolean',
  n: 'number',
  s: 'string',
  t: 'table',
  v: 'any',
  f: 'function',
  u: 'userdata',
  o: 'MrxTask',  // "o*" is object-handle in-engine, almost always a task instance
};

export function inferType(fieldName, literal) {
  // Prefer a type we can read off the literal.
  if (literal?.type === 'StringLiteral')      return 'string';
  if (literal?.type === 'BooleanLiteral')     return 'boolean';
  if (literal?.type === 'NumericLiteral')     return 'number';
  if (literal?.type === 'TableConstructorExpression') return 'table';
  if (literal?.type === 'NilLiteral')         return 'nil';
  if (literal?.type === 'FunctionDeclaration') return 'function';
  // Fall back to Hungarian prefix.
  const m = /^_?([a-z])[A-Z_0-9]/.exec(fieldName || '');
  if (m) return HUNGARIAN[m[1]] ?? 'any';
  return 'any';
}

function literalPreview(node) {
  if (!node) return null;
  if (node.type === 'StringLiteral')  return unquote(node.raw);
  if (node.type === 'BooleanLiteral') return node.value;
  if (node.type === 'NumericLiteral') return node.value;
  if (node.type === 'NilLiteral')     return null;
  if (node.type === 'TableConstructorExpression') return '<nested table>';
  if (node.type === 'FunctionDeclaration')         return '<function>';
  return '<expr>';
}

// --- top-level walker scaffolding ---------------------------------------

function parseLua(text, filePath) {
  return luaparse.parse(text, {
    luaVersion: '5.1',
    comments: false,
    locations: true,
    ranges: true,
    scope: false,
    wait: false,
  });
}

// `inherit(...)` and `import(...)` must be top-level call statements.
function topCalls(chunk, fnName) {
  const out = [];
  for (const stmt of chunk.body) {
    if (stmt.type !== 'CallStatement') continue;
    const call = stmt.expression;
    if (call?.type !== 'CallExpression' && call?.type !== 'StringCallExpression') continue;
    if (call.base?.type !== 'Identifier' || call.base.name !== fnName) continue;
    const arg = call.arguments?.[0] ?? call.argument;
    const s = strValue(arg);
    if (s) out.push({ name: s, line: lineOf(call) });
  }
  return out;
}

// --- class-mode extractor ----------------------------------------------

/**
 * Walk a function body / expression subtree and record method/field access patterns.
 * `ctx` accumulates arrays we mutate. `tConfigAliases` holds local names bound to
 * `self:GetConfig()` so later `<alias>.X` reads classify as config-field access.
 */
function visitExpr(node, ctx, tConfigAliases) {
  if (!node || typeof node !== 'object') return;

  switch (node.type) {
    case 'CallExpression':
    case 'StringCallExpression':
    case 'TableCallExpression': {
      visitExpr(node.base, ctx, tConfigAliases);
      const args = node.arguments ?? (node.argument ? [node.argument] : []);
      for (const a of args) visitExpr(a, ctx, tConfigAliases);
      break;
    }
    case 'MemberExpression': {
      // Config-alias field read: `<alias>.X`
      if (
        node.indexer === '.' &&
        node.base?.type === 'Identifier' &&
        tConfigAliases.has(node.base.name)
      ) {
        ctx.configRead.push({ field: node.identifier.name, line: lineOf(node) });
      }
      // self:X / self.X  (method OR field) -> defer to the ":" case below for :X,
      // handle plain `self._tConfig.X` here.
      if (
        node.indexer === '.' &&
        node.base?.type === 'MemberExpression' &&
        node.base.indexer === '.' &&
        node.base.base?.type === 'Identifier' &&
        node.base.base.name === 'self' &&
        node.base.identifier.name === '_tConfig'
      ) {
        ctx.configRead.push({ field: node.identifier.name, line: lineOf(node) });
      }
      visitExpr(node.base, ctx, tConfigAliases);
      break;
    }
    case 'IndexExpression':
      visitExpr(node.base, ctx, tConfigAliases);
      visitExpr(node.index, ctx, tConfigAliases);
      break;
    case 'LogicalExpression':
    case 'BinaryExpression':
      visitExpr(node.left, ctx, tConfigAliases);
      visitExpr(node.right, ctx, tConfigAliases);
      break;
    case 'UnaryExpression':
      visitExpr(node.argument, ctx, tConfigAliases);
      break;
    case 'TableConstructorExpression':
      for (const f of node.fields ?? []) {
        if (f.key)   visitExpr(f.key,   ctx, tConfigAliases);
        if (f.value) visitExpr(f.value, ctx, tConfigAliases);
      }
      break;
    case 'FunctionDeclaration':
      // Nested function: new scope for config aliases (don't inherit outer).
      walkMethodBody(node.body ?? [], ctx, new Set());
      break;
    default:
      // Leaf nodes (Identifier, StringLiteral, NumericLiteral, …) — nothing to do.
      break;
  }
}

/**
 * Pull "methods called on <receiver>" out of a chained call expression.
 * Returns {method, line} if the top of the chain matches `self:X()`, else null.
 * Receiver matcher is a predicate on the base node.
 */
function methodOnReceiver(callNode, isReceiver) {
  // call -> base is MemberExpression with ':' indexer; member.base is the receiver.
  if (callNode.type !== 'CallExpression' && callNode.type !== 'StringCallExpression' && callNode.type !== 'TableCallExpression') return null;
  const base = callNode.base;
  if (!base || base.type !== 'MemberExpression' || base.indexer !== ':') return null;
  if (!isReceiver(base.base)) return null;
  return { method: base.identifier.name, line: lineOf(callNode) };
}

const isSelf = (n) => n?.type === 'Identifier' && n.name === 'self';
const isSelfColonCall = (n, meth) =>
  n?.type === 'CallExpression' &&
  n.base?.type === 'MemberExpression' &&
  n.base.indexer === ':' &&
  isSelf(n.base.base) &&
  n.base.identifier.name === meth;

/**
 * Walk a method/function body, mutating ctx with every classified call/field access.
 * ctx accumulates: methodsDef, callsOnSelf, callsOnSuper, callsOnMissionAncestor,
 * callsOnParent, configRead, dataTablesRead.
 */
function walkMethodBody(body, ctx, tConfigAliases) {
  // First pass: locals assigned from self:GetConfig(), self:GetParent(), self:GetMissionAncestor().
  // These become receiver aliases we track in a parallel map.
  const aliases = {
    missionAncestor: new Set(),
    parent: new Set(),
  };

  function recordAliasBindings(stmt) {
    if (stmt.type !== 'LocalStatement' && stmt.type !== 'AssignmentStatement') return;
    const vars = stmt.variables ?? [];
    const inits = stmt.init ?? [];
    for (let i = 0; i < vars.length; i++) {
      const v = vars[i];
      const init = inits[i];
      if (!v || !init || v.type !== 'Identifier') continue;
      if (isSelfColonCall(init, 'GetConfig')) tConfigAliases.add(v.name);
      else if (isSelfColonCall(init, 'GetMissionAncestor')) aliases.missionAncestor.add(v.name);
      else if (isSelfColonCall(init, 'GetParent')) aliases.parent.add(v.name);
    }
  }

  function visit(node) {
    if (!node || typeof node !== 'object') return;

    // Record alias bindings as we see them (locals before uses).
    if (node.type === 'LocalStatement' || node.type === 'AssignmentStatement') recordAliasBindings(node);

    switch (node.type) {
      case 'CallExpression':
      case 'StringCallExpression':
      case 'TableCallExpression': {
        // self:X(...)
        const selfHit = methodOnReceiver(node, isSelf);
        if (selfHit) ctx.callsOnSelf.push(selfHit);

        // <alias>:X(...) where alias was bound to self:GetMissionAncestor()
        const maHit = methodOnReceiver(node, (n) => n?.type === 'Identifier' && aliases.missionAncestor.has(n.name));
        if (maHit) ctx.callsOnMissionAncestor.push(maHit);

        // self:GetMissionAncestor():X() — inline chain
        if (
          node.base?.type === 'MemberExpression' &&
          node.base.indexer === ':' &&
          isSelfColonCall(node.base.base, 'GetMissionAncestor')
        ) {
          ctx.callsOnMissionAncestor.push({ method: node.base.identifier.name, line: lineOf(node) });
        }

        // <alias>:X() where alias was bound to self:GetParent()
        const parHit = methodOnReceiver(node, (n) => n?.type === 'Identifier' && aliases.parent.has(n.name));
        if (parHit) ctx.callsOnParent.push(parHit);

        // self:GetParent():X() — inline chain
        if (
          node.base?.type === 'MemberExpression' &&
          node.base.indexer === ':' &&
          isSelfColonCall(node.base.base, 'GetParent')
        ) {
          ctx.callsOnParent.push({ method: node.base.identifier.name, line: lineOf(node) });
        }

        // <Module>.X(self, ...) — super call. Module name must be in ctx.inheritAncestors.
        if (
          node.base?.type === 'MemberExpression' &&
          node.base.indexer === '.' &&
          node.base.base?.type === 'Identifier' &&
          ctx.inheritAncestors.has(node.base.base.name)
        ) {
          const args = node.arguments ?? [];
          if (args[0]?.type === 'Identifier' && args[0].name === 'self') {
            ctx.callsOnSuper.push({
              module: node.base.base.name,
              method: node.base.identifier.name,
              line: lineOf(node),
            });
          }
        }

        // <Module>.<field>[...] — track imported-data-table reads.
        if (
          node.base?.type === 'MemberExpression' &&
          node.base.indexer === '.' &&
          node.base.base?.type === 'Identifier' &&
          ctx.imports.has(node.base.base.name)
        ) {
          // Function call into an imported module isn't a data-table read; skip. Pure
          // member-expr reads are handled below in the member-expression traversal.
        }
        break;
      }

      case 'MemberExpression': {
        // Imported-module.field — data-table read.
        if (
          node.indexer === '.' &&
          node.base?.type === 'Identifier' &&
          ctx.imports.has(node.base.name)
        ) {
          ctx.dataTablesRead.push({
            module: node.base.name,
            field: node.identifier.name,
            line: lineOf(node),
          });
        }
        // Config-alias field read: `<alias>.X` where <alias> was bound to self:GetConfig().
        if (
          node.indexer === '.' &&
          node.base?.type === 'Identifier' &&
          tConfigAliases.has(node.base.name)
        ) {
          ctx.configRead.push({ field: node.identifier.name, line: lineOf(node) });
        }
        // Direct `self._tConfig.X` — rarer but used in the shipped MrxTask base.
        if (
          node.indexer === '.' &&
          node.base?.type === 'MemberExpression' &&
          node.base.indexer === '.' &&
          node.base.base?.type === 'Identifier' &&
          node.base.base.name === 'self' &&
          node.base.identifier?.name === '_tConfig'
        ) {
          ctx.configRead.push({ field: node.identifier.name, line: lineOf(node) });
        }
        // Direct one-liner `self:GetConfig().X` without an intermediate local.
        // Common in short accessors like `function GetName(self) return self:GetConfig().sName end`.
        if (
          node.indexer === '.' &&
          node.base?.type === 'CallExpression' &&
          isSelfColonCall(node.base, 'GetConfig')
        ) {
          ctx.configRead.push({ field: node.identifier.name, line: lineOf(node) });
        }
        break;
      }

      // Statements/expressions that contain children we must descend into.
      default: break;
    }

    // Generic descent.
    for (const key of Object.keys(node)) {
      if (key === 'loc' || key === 'range') continue;
      const child = node[key];
      if (Array.isArray(child)) child.forEach(visit);
      else if (child && typeof child === 'object' && typeof child.type === 'string') visit(child);
    }
  }

  for (const stmt of body) visit(stmt);
}

function extractClass(chunk, filePath, text) {
  const inherits = topCalls(chunk, 'inherit');
  const imports  = topCalls(chunk, 'import');
  const inheritChain = inherits.map((i) => i.name);  // immediate parent only; multi-level walk is `resolveInheritChain`
  const inheritAncestors = new Set(inheritChain);     // used by super-call detection
  const importSet = new Set(imports.map((i) => i.name));

  const methodsDefined = [];
  const callsOnSelf = [];
  const callsOnSuper = [];
  const callsOnMissionAncestor = [];
  const callsOnParent = [];
  const configRead = [];
  const dataTablesRead = [];
  // Class-mode files frequently also carry top-level data (`wifmissiondata.lua` has 5 helper
  // functions AND the massive tMissionData registry; `wifpmcinterior.lua` has methods AND
  // _tStarters). Extract both facets so the artifact's data side isn't lost.
  const tables = [];
  const scalars = [];

  // Top-level `function Name(self, ...) ... end`
  for (const stmt of chunk.body) {
    if (stmt.type !== 'FunctionDeclaration') continue;
    const id = stmt.identifier;
    if (!id) continue;

    // `function Name(self, ...)` — simple identifier.
    if (id.type === 'Identifier') {
      methodsDefined.push({ name: id.name, line: lineOf(stmt) });
    }
    // `function Class:Name(args)` or `function Class.Name(args)` — namespaced.
    else if (id.type === 'MemberExpression') {
      const className = identName(id.base);
      methodsDefined.push({
        name: id.identifier.name,
        line: lineOf(stmt),
        on: className,
        kind: id.indexer === ':' ? 'colon' : 'dot',
      });
    }

    const ctx = {
      inheritAncestors,
      imports: importSet,
      callsOnSelf,
      callsOnSuper,
      callsOnMissionAncestor,
      callsOnParent,
      configRead,
      dataTablesRead,
    };
    walkMethodBody(stmt.body ?? [], ctx, new Set());
  }

  // Walk top-level assignments for the data facet (same extraction path as data-mode).
  for (const stmt of chunk.body) {
    if (stmt.type !== 'AssignmentStatement') continue;
    const vars = stmt.variables ?? [];
    const inits = stmt.init ?? [];
    for (let i = 0; i < vars.length; i++) {
      const v = vars[i];
      const init = inits[i];
      if (!v || !init) continue;
      const lhsName = identName(v);
      if (!lhsName) continue;
      if (init.type === 'TableConstructorExpression') {
        const info = extractTableRecords(init);
        tables.push({
          name: lhsName,
          line: lineOf(stmt),
          shape: info.shape,
          record_schema: info.schema,
          records: info.records,
          record_count: info.record_count ?? info.records.length,
        });
      } else if (
        init.type === 'StringLiteral' ||
        init.type === 'BooleanLiteral' ||
        init.type === 'NumericLiteral' ||
        init.type === 'NilLiteral'
      ) {
        scalars.push({ name: lhsName, line: lineOf(stmt), shape: 'scalar', value: literalPreview(init) });
      }
    }
  }

  // Dedup helpers.
  const dedupBy = (arr, keyFn) => {
    const seen = new Set();
    const out = [];
    for (const x of arr) {
      const k = keyFn(x);
      if (!seen.has(k)) { seen.add(k); out.push(x); }
    }
    return out;
  };

  return {
    kind: 'class',
    class: path.basename(filePath, '.lua'),
    source_path: filePath,
    inherit_chain: inheritChain.length ? [path.basename(filePath, '.lua'), ...inheritChain] : [path.basename(filePath, '.lua')],
    imports: imports.map((i) => i.name),
    methods_defined: methodsDefined,
    calls_on_self:               dedupBy(callsOnSelf,               (x) => `${x.method}@${x.line}`),
    calls_on_super:              dedupBy(callsOnSuper,              (x) => `${x.module}.${x.method}@${x.line}`),
    calls_on_mission_ancestor:   dedupBy(callsOnMissionAncestor,    (x) => `${x.method}@${x.line}`),
    calls_on_parent:             dedupBy(callsOnParent,             (x) => `${x.method}@${x.line}`),
    config_fields_read:          [...new Set(configRead.map((x) => x.field))],
    config_fields_written:       [],   // writes are not yet tracked
    data_tables_read:            dedupBy(dataTablesRead,            (x) => `${x.module}.${x.field}@${x.line}`),
    tables: [...tables, ...scalars],
    warnings: [],
  };
}

// --- data-mode extractor ------------------------------------------------

function extractTableRecords(tableNode) {
  // record_map: keys are quoted strings => map of records
  // ordered_list: array-style (field.key === null) => list
  // nested fallback: everything else
  const fields = tableNode.fields ?? [];
  if (fields.length === 0) return { shape: 'nested', records: [], schema: {} };

  const keyedStringCount = fields.filter((f) => f.type === 'TableKeyString' || (f.type === 'TableKey' && f.key?.type === 'StringLiteral')).length;
  const arrayCount       = fields.filter((f) => f.type === 'TableValue').length;

  if (keyedStringCount >= Math.max(1, fields.length - 1)) {
    // record_map
    const records = [];
    const schemaCounts = {};
    const schemaExamples = {};
    for (const f of fields) {
      const keyName = f.type === 'TableKeyString' ? f.key.name : strValue(f.key);
      if (!keyName) continue;

      // The value must itself be a table literal for us to extract per-record fields.
      const rec = { key: keyName, line: lineOf(f), fields: {} };
      if (f.value?.type === 'TableConstructorExpression') {
        for (const sub of f.value.fields ?? []) {
          const subKey = sub.type === 'TableKeyString' ? sub.key.name : strValue(sub.key);
          if (!subKey) continue;
          const val = literalPreview(sub.value);
          rec.fields[subKey] = val;
          schemaCounts[subKey] = (schemaCounts[subKey] ?? 0) + 1;
          if (!(subKey in schemaExamples)) schemaExamples[subKey] = sub.value;
        }
      } else {
        rec.fields._value = literalPreview(f.value);
      }
      records.push(rec);
    }
    const totalRecords = records.length;
    const record_schema = {};
    for (const [key, count] of Object.entries(schemaCounts)) {
      record_schema[key] = {
        type: inferType(key, schemaExamples[key]),
        required: count === totalRecords,
        count,
      };
    }
    return { shape: 'record_map', records, schema: record_schema, record_count: totalRecords };
  }

  if (arrayCount >= Math.max(1, fields.length - 1)) {
    // ordered_list
    const items = fields
      .filter((f) => f.type === 'TableValue')
      .map((f, i) => ({ index: i + 1, line: lineOf(f), value: literalPreview(f.value) }));
    return { shape: 'ordered_list', records: items, schema: {}, record_count: items.length };
  }

  return { shape: 'nested', records: [], schema: {}, record_count: 0 };
}

function extractData(chunk, filePath, text) {
  const tables = [];
  const scalars = [];
  // A data file can still declare methods on a table (`function T.M(self) ... end`,
  // `function T:M(args) ... end`). Collect them under `methods_defined` keyed by the receiver,
  // so a table that acts as a class — including an in-mod shim parenting a MrxTask subtree —
  // can be queried the same way as a true class: "does T declare method M?".
  const methodsDefined = [];

  // Walk top-level assignments: `<ident>[.field] = { ... }` or `<ident> = <scalar>`.
  for (const stmt of chunk.body) {
    if (stmt.type !== 'AssignmentStatement') continue;
    const vars = stmt.variables ?? [];
    const inits = stmt.init ?? [];
    for (let i = 0; i < vars.length; i++) {
      const v = vars[i];
      const init = inits[i];
      if (!v || !init) continue;

      // Compose the full LHS name as a string: `Foo`, `Foo.bar`, …
      const lhsName = identName(v);
      if (!lhsName) continue;

      if (init.type === 'TableConstructorExpression') {
        const info = extractTableRecords(init);
        tables.push({
          name: lhsName,
          line: lineOf(stmt),
          shape: info.shape,
          record_schema: info.schema,
          records: info.records,
          record_count: info.record_count ?? info.records.length,
        });
      } else if (
        init.type === 'StringLiteral' ||
        init.type === 'BooleanLiteral' ||
        init.type === 'NumericLiteral' ||
        init.type === 'NilLiteral'
      ) {
        scalars.push({ name: lhsName, line: lineOf(stmt), shape: 'scalar', value: literalPreview(init) });
      }
    }
  }

  // Walk top-level function declarations for namespaced forms.
  for (const stmt of chunk.body) {
    if (stmt.type !== 'FunctionDeclaration') continue;
    const id = stmt.identifier;
    if (!id) continue;
    if (id.type === 'Identifier') {
      methodsDefined.push({ name: id.name, line: lineOf(stmt), on: null, kind: 'free' });
    } else if (id.type === 'MemberExpression') {
      methodsDefined.push({
        name: id.identifier.name,
        line: lineOf(stmt),
        on: identName(id.base),
        kind: id.indexer === ':' ? 'colon' : 'dot',
      });
    }
  }

  const warnings = [];
  // A `WifMissionData = WifMissionData or {}` idiom at module top is harmless but worth noting.
  for (const stmt of chunk.body) {
    if (
      stmt.type === 'AssignmentStatement' &&
      stmt.init?.[0]?.type === 'LogicalExpression' &&
      stmt.init[0].operator === 'or'
    ) {
      warnings.push({ kind: 'module_table_idiom', line: lineOf(stmt) });
    }
  }

  return {
    kind: 'data',
    module: path.basename(filePath, '.lua'),
    source_path: filePath,
    tables: [...tables, ...scalars],
    methods_defined: methodsDefined,
    warnings,
  };
}

// --- top-level dispatch ------------------------------------------------

/**
 * Parse one Lua file and return its structured API record.
 * Dispatches to class-mode on first top-level inherit(), else to data-mode.
 */
export function analyzeFile(absPath) {
  const text = fs.readFileSync(absPath, 'utf8');
  let chunk;
  try {
    chunk = parseLua(text, absPath);
  } catch (e) {
    return {
      kind: 'parse_error',
      source_path: absPath,
      error: e.message,
      line: e.line ?? null,
    };
  }
  // Classify as a class if the file has either (a) `inherit(...)` at the top, OR (b) any
  // module-scope `function Name(...)` definition. Shipped modules like `mrxtask.lua` have no
  // inherit but ARE classes (they define the base class every subclass inherits from); a pure
  // registry like `wifmissiondata.lua` has only table assignments and classifies as data.
  const hasInherit = topCalls(chunk, 'inherit').length > 0;
  const hasModuleFns = chunk.body.some((s) => s.type === 'FunctionDeclaration');
  if (hasInherit || hasModuleFns) return extractClass(chunk, absPath, text);
  return extractData(chunk, absPath, text);
}

/**
 * Walk a Lua tree and parse every .lua file into one Map<name, record>.
 * Classes keyed by their file-basename (same convention as `inherit("Foo")` uses).
 * Data modules keyed by their capitalised file-basename (matches shipped `WifMissionData` form).
 */
export function allArtifacts(rootDir) {
  const results = new Map();

  function walk(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.isFile() && entry.name.endsWith('.lua')) {
        try {
          const api = analyzeFile(full);
          const key = api.kind === 'class' ? api.class : api.module;
          if (key) results.set(key, api);
        } catch (e) {
          results.set(full, { kind: 'walk_error', source_path: full, error: e.message });
        }
      }
    }
  }

  walk(rootDir);
  return results;
}

/**
 * Starting from a ClassAPI, follow its `inherit_chain` through sibling files until the chain
 * terminates. Merges inherited `methods_defined` into a cumulative set the caller can consult
 * for method-resolution. Loader is `(className) -> ClassAPI | null`, letting callers plug in
 * a cache or a filesystem walker.
 */
export function resolveInheritChain(cls, loader) {
  if (cls.kind !== 'class') return cls;
  const chain = [cls.class];
  const seen = new Set(chain);
  const inheritedMethods = [];

  let current = cls;
  while (current.inherit_chain && current.inherit_chain.length > 1) {
    // The first entry is `current.class` itself; the next is the immediate parent.
    const parentName = current.inherit_chain[1];
    if (!parentName || seen.has(parentName)) break;
    const parent = loader(parentName);
    if (!parent || parent.kind !== 'class') break;
    chain.push(parentName);
    seen.add(parentName);
    for (const m of parent.methods_defined ?? []) {
      inheritedMethods.push({ ...m, inherited_from: parent.class });
    }
    current = parent;
  }

  return {
    ...cls,
    inherit_chain: chain,
    inherited_methods: inheritedMethods,
  };
}
