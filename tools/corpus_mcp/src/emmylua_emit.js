/**
 * EmmyLua stub emitter.
 *
 * Walks the Lua artifact index and emits one `.lua` stub per class, plus one `---@class` record
 * type per record_map data table. Output is intended for sumneko.lua (via `.luarc.json
 * workspace.library`) and for ingestion back into the LanceDB index as a type model.
 *
 * Output is self-contained: each file names its own source and the artifact it describes, but
 * carries no project-internal cross-references. Readers get types; they get them without
 * context they would have to chase elsewhere.
 */
import fs from 'node:fs';
import path from 'node:path';
import { allArtifacts, inferType, HUNGARIAN } from './lua_analyzer.js';

const LUA_ROOTS = [
  'tools/wad_simulator/workshop_data/lua',
  'tools/wad_simulator/workshop_data/shipments',
];

function esc(s) {
  // Keep EmmyLua-safe characters, replace anything else with `_` so sumneko stays happy.
  return String(s).replace(/[^A-Za-z0-9_.]/g, '_');
}

// Normalise an artifact's name to its import()-style spelling (CamelCase) when we can infer one,
// else keep file-basename form. Convention across the shipped corpus: `inherit("Foo")` is written
// in CamelCase; the file on disk is `foo.lua`. We can't reverse that, so prefer the file-basename
// and let callers who care about the import-form look it up by matching the inherit chains in
// other files.
function stubName(name) {
  return esc(name);
}

function emitHeader(name, sourcePath) {
  return [
    '--[[',
    `  ${name}`,
    `  Generated stub. Source: ${sourcePath}`,
    '  Do not edit by hand; this file is overwritten.',
    ']]',
    '',
  ].join('\n');
}

function emitClassStub(cls) {
  const name = stubName(cls.class);
  const parent = cls.inherit_chain?.[1];
  const lines = [];
  lines.push(emitHeader(name, cls.source_path));

  // The class type.
  if (parent) {
    lines.push(`---@class ${name} : ${stubName(parent)}`);
  } else {
    lines.push(`---@class ${name}`);
  }
  // Config fields on the class itself as @field entries (Hungarian-prefix typed).
  for (const field of cls.config_fields_read ?? []) {
    const t = inferType(field, null);
    lines.push(`---@field ${esc(field)} ${t} (config: read via self:GetConfig())`);
  }
  lines.push(`local ${name} = {}`);
  lines.push('');

  // Methods — one per entry in methods_defined. Dot vs colon form matters for sumneko.
  for (const m of cls.methods_defined ?? []) {
    if (m.on && m.on !== name) continue;              // only this class's own methods
    lines.push(`---@param self ${name}`);
    lines.push(`function ${name}:${esc(m.name)}(...) end`);
  }

  // Inherited methods (if the inherit chain was resolved) — purely informational so hover shows
  // what's available even without recursing through the parent file.
  if (cls.inherited_methods?.length) {
    lines.push('');
    lines.push('-- Inherited methods:');
    for (const m of cls.inherited_methods) {
      lines.push(`--   ${esc(m.inherited_from)}:${esc(m.name)}(self, ...)`);
    }
  }

  lines.push('');
  lines.push(`return ${name}`);
  return lines.join('\n') + '\n';
}

function emitDataModuleStub(mod) {
  const modName = stubName(mod.module ?? mod.class);
  const lines = [];
  lines.push(emitHeader(modName, mod.source_path));

  // For each record_map table, emit a @class with @field entries, then a @type on the table itself.
  const recordClasses = [];
  for (const t of mod.tables ?? []) {
    if (t.shape === 'record_map') {
      const recName = `${modName}.${esc(t.name)}Record`;
      lines.push(`---@class ${recName}`);
      for (const [field, info] of Object.entries(t.record_schema ?? {})) {
        const required = info.required ? '' : '?';
        lines.push(`---@field ${esc(field)}${required} ${info.type ?? 'any'}`);
      }
      lines.push('');
      recordClasses.push({ table: t.name, recName });
    }
  }

  // The module object with its tables / scalars.
  lines.push(`---@class ${modName}`);
  for (const t of mod.tables ?? []) {
    if (t.shape === 'record_map') {
      const rc = recordClasses.find((r) => r.table === t.name);
      lines.push(`---@field ${esc(t.name)} table<string, ${rc.recName}>`);
    } else if (t.shape === 'ordered_list') {
      lines.push(`---@field ${esc(t.name)} any[]`);
    } else if (t.shape === 'scalar') {
      lines.push(`---@field ${esc(t.name)} ${inferType(t.name, null)}`);
    } else {
      lines.push(`---@field ${esc(t.name)} table`);
    }
  }
  lines.push(`local ${modName} = {}`);
  lines.push('');

  // Methods on data modules (helper functions like wifmissiondata.GetMissionTitle).
  for (const m of mod.methods_defined ?? []) {
    if (m.on && m.on !== modName) continue;
    lines.push(`function ${modName}.${esc(m.name)}(...) end`);
  }

  lines.push('');
  lines.push(`return ${modName}`);
  return lines.join('\n') + '\n';
}

function resolveRepoRoot() {
  if (process.env.CORPUS_REPO_ROOT) return path.resolve(process.env.CORPUS_REPO_ROOT);
  const here = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([a-zA-Z]:)/, '$1'));
  // src/ -> corpus_mcp/ -> tools/ -> repo root.
  return path.resolve(here, '..', '..', '..');
}

/**
 * Emit stubs for every artifact under the Lua roots.
 *   outDir: where to write (default: <repo>/tools/emmylua_stubs/mercs2).
 * Returns a summary + the discovered-globals set so writeLuarc can pick it up.
 */
export function emitAll({ outDir, repoRoot } = {}) {
  const root = repoRoot ?? resolveRepoRoot();
  const out = outDir ?? path.join(root, 'tools', 'emmylua_stubs', 'mercs2');
  const scriptDir = path.join(out, 'script');
  fs.mkdirSync(scriptDir, { recursive: true });

  const written = { classes: 0, dataModules: 0, recordShapes: 0 };
  const discoveredGlobals = new Set();
  for (const rel of LUA_ROOTS) {
    const abs = path.resolve(root, rel);
    if (!fs.existsSync(abs)) continue;
    const batch = allArtifacts(abs);
    for (const api of batch.values()) {
      if (api.kind !== 'class' && api.kind !== 'data') continue;
      const fileName = `${stubName(api.class ?? api.module)}.lua`;
      const target = path.join(scriptDir, fileName);
      const body = api.kind === 'class' ? emitClassStub(api) : emitDataModuleStub(api);
      fs.writeFileSync(target, body);
      discoveredGlobals.add(stubName(api.class ?? api.module));
      for (const imp of api.imports ?? []) discoveredGlobals.add(stubName(imp));
      for (const call of api.calls_on_super ?? []) discoveredGlobals.add(stubName(call.module));
      for (const read of api.data_tables_read ?? []) discoveredGlobals.add(stubName(read.module));
      if (api.kind === 'class') written.classes += 1;
      else {
        written.dataModules += 1;
        for (const t of api.tables ?? []) if (t.shape === 'record_map') written.recordShapes += 1;
      }
    }
  }
  return { outDir: out, scriptDir, globals: [...discoveredGlobals].sort(), ...written };
}

/**
 * Write a `.luarc.json` at the repo root wiring sumneko to the stub libraries + declaring every
 * engine namespace as a known global (so bare refs don't warn). Called by the emitter or by the
 * MCP tool; writing it as part of stub emission keeps the workspace in a usable state end-to-end.
 */
export function writeLuarc({ repoRoot, stubRoot, globals } = {}) {
  const root = repoRoot ?? resolveRepoRoot();
  const stub = stubRoot ?? path.join(root, 'tools', 'emmylua_stubs', 'mercs2');
  const target = path.join(root, '.luarc.json');
  const config = {
    runtime: { version: 'Lua 5.1' },
    workspace: {
      library: [
        path.relative(root, path.join(stub, 'engine')).replace(/\\/g, '/'),
        path.relative(root, path.join(stub, 'script')).replace(/\\/g, '/'),
      ],
      checkThirdParty: false,
      ignoreDir: ['node_modules', 'output', 'storage'],
    },
    diagnostics: {
      globals: globals ?? [],
      disable: ['lowercase-global'],
    },
  };
  fs.writeFileSync(target, JSON.stringify(config, null, 2) + '\n');
  return { path: target, config };
}
