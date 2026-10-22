import * as lancedb from '@lancedb/lancedb';
import { DB_PATH, TABLE_NAME } from './config.js';

let dbPromise = null;

export function connect() {
  if (!dbPromise) dbPromise = lancedb.connect(DB_PATH);
  return dbPromise;
}

export async function openTable() {
  const db = await connect();
  const names = await db.tableNames();
  if (!names.includes(TABLE_NAME)) return null;
  return db.openTable(TABLE_NAME);
}

export async function createTable(firstRows) {
  const db = await connect();
  return db.createTable(TABLE_NAME, firstRows, { mode: 'create' });
}

/**
 * The row shape `ingest.js` writes, column for column. LanceDB infers a table's columns from the
 * first rows it is created with; a table created by an older row shape keeps its old columns until
 * `migrateColumns` changes them in place.
 */
export const ROW_COLUMNS = [
  'id', 'source', 'path', 'title', 'chunk', 'text', 'text_hash', 'file_hash', 'mtime',
  'image_id', 'image_sha256', 'va', 'images', 'addrs', 'meta', 'vector',
];

/**
 * The column changes `migrateColumns` knows, from each older row shape to ROW_COLUMNS. ADDED
 * columns are string columns filled with '' on every existing row (the value every non-ghidra row
 * holds; the old ghidra rows are replaced by the next ghidra ingest). DROPPED columns are removed.
 */
const MIGRATION_ADDED = ['image_id', 'image_sha256', 'va', 'images'];
const MIGRATION_DROPPED = ['fn_addr'];

function columnDiff(have) {
  return {
    missing: ROW_COLUMNS.filter((c) => !have.includes(c)),
    extra: have.filter((c) => !ROW_COLUMNS.includes(c)),
  };
}

/** Throw when `table`'s columns are not ROW_COLUMNS. */
export async function checkColumns(table) {
  const have = (await table.schema()).fields.map((f) => f.name);
  const { missing, extra } = columnDiff(have);
  if (missing.length || extra.length) {
    throw new Error(
      `corpus table '${TABLE_NAME}' at ${DB_PATH} has columns [${have.join(', ')}] but the row shape is ` +
      `[${ROW_COLUMNS.join(', ')}] (missing: ${missing.join(', ') || 'none'}; extra: ${extra.join(', ') || 'none'}). ` +
      'Run `npm run ingest` in tools/corpus_mcp: it migrates the columns in place.',
    );
  }
}

/**
 * Bring an older table's columns to ROW_COLUMNS in place, keeping every row and vector. A column
 * difference outside MIGRATION_ADDED / MIGRATION_DROPPED has no migration and is a hard failure.
 * Returns the columns added and dropped.
 */
export async function migrateColumns(table) {
  const have = (await table.schema()).fields.map((f) => f.name);
  const { missing, extra } = columnDiff(have);
  const unknown = [...missing.filter((c) => !MIGRATION_ADDED.includes(c)), ...extra.filter((c) => !MIGRATION_DROPPED.includes(c))];
  if (unknown.length) {
    throw new Error(
      `corpus table '${TABLE_NAME}' at ${DB_PATH} has columns [${have.join(', ')}]; no migration is defined for ` +
      `[${unknown.join(', ')}] (db.js MIGRATION_ADDED / MIGRATION_DROPPED)`,
    );
  }
  if (missing.length) await table.addColumns(missing.map((name) => ({ name, valueSql: "''" })));
  if (extra.length) await table.dropColumns(extra);
  await checkColumns(table);
  return { added: missing, dropped: extra };
}

export function esc(s) {
  return s.replace(/'/g, "''");
}

export { lancedb };
