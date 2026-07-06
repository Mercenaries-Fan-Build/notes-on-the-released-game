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

export function esc(s) {
  return s.replace(/'/g, "''");
}

export { lancedb };
