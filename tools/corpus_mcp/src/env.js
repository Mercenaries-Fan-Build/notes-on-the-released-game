import fs from 'node:fs';

/** Parse `.env` text into a plain object.
 *  Supports: blank lines, `#` comments, optional `export ` prefix,
 *  `KEY=VALUE`, and single/double-quoted values (double quotes honour
 *  `\n`/`\t`/`\\` escapes). Unquoted values are trimmed of surrounding
 *  whitespace; `#` is only a comment at line start or after whitespace on
 *  an unquoted value. Later duplicate keys win. */
export function parseEnv(text) {
  const out = {};
  for (let line of String(text).replace(/\r\n/g, '\n').split('\n')) {
    line = line.trim();
    if (!line || line.startsWith('#')) continue;
    if (line.startsWith('export ')) line = line.slice(7).trim();
    const eq = line.indexOf('=');
    if (eq <= 0) continue;
    const key = line.slice(0, eq).trim();
    if (!/^[A-Za-z_][A-Za-z0-9_.]*$/.test(key)) continue;
    let val = line.slice(eq + 1).trim();
    if (val[0] === '"' && val.endsWith('"') && val.length > 1) {
      val = val.slice(1, -1).replace(/\\n/g, '\n').replace(/\\t/g, '\t').replace(/\\\\/g, '\\');
    } else if (val[0] === "'" && val.endsWith("'") && val.length > 1) {
      val = val.slice(1, -1);
    } else {
      const hash = val.search(/\s#/);
      if (hash >= 0) val = val.slice(0, hash).trim();
    }
    out[key] = val;
  }
  return out;
}

/** Apply parsed keys to `process.env`, WITHOUT clobbering variables that are
 *  already set — so a real environment variable (from the shell or the MCP
 *  launcher) always wins over the `.env` file. Returns the keys applied. */
export function applyEnv(vars, env = process.env) {
  const applied = [];
  for (const [k, v] of Object.entries(vars)) {
    if (env[k] === undefined) { env[k] = v; applied.push(k); }
  }
  return applied;
}

/** Load a `.env` file (if it exists) into process.env. No-op when absent. */
export function loadEnvFile(file, env = process.env) {
  let text;
  try { text = fs.readFileSync(file, 'utf8'); } catch { return []; }
  return applyEnv(parseEnv(text), env);
}
