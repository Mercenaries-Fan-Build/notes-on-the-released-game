#!/usr/bin/env node
/** Incremental corpus ingester.
 *
 *   node src/ingest.js                     # all sources
 *   node src/ingest.js --sources doc,memory,tool
 *   node src/ingest.js --full              # ignore file-hash cache, re-embed everything
 *
 * Skip logic: a doc whose (path, file_hash) already matches the table is
 * untouched. Changed docs are delete+reinserted, reusing embeddings for
 * chunks whose text_hash is unchanged. Docs that disappeared from a source
 * are deleted.
 */
import { SOURCES } from './config.js';
import { allDocs } from './sources.js';
import { sha256, extractAddrs } from './chunk.js';
import { embedPassages } from './embed.js';
import { openTable, createTable, esc, lancedb } from './db.js';

const argv = process.argv.slice(2);
function argVal(name) {
  const i = argv.indexOf(name);
  return i >= 0 ? argv[i + 1] : null;
}

export async function ingest({ sources, full = false, log = (m) => console.error(m) } = {}) {
  const names = sources?.length ? sources : Object.keys(SOURCES);
  for (const n of names) if (!SOURCES[n]) throw new Error(`unknown source '${n}' (valid: ${Object.keys(SOURCES).join(', ')})`);

  let table = await openTable();

  // Snapshot existing (path -> file_hash) once for skip checks.
  const existing = new Map();
  if (table && !full) {
    const rows = await table.query().select(['path', 'file_hash', 'source']).toArray();
    for (const r of rows) if (names.includes(r.source)) existing.set(r.path, r.file_hash);
  } else if (table && full) {
    const rows = await table.query().select(['path', 'source']).toArray();
    for (const r of rows) if (names.includes(r.source)) existing.set(r.path, '!force!');
  }

  const seenPaths = new Set();
  const stats = { docs: 0, skipped: 0, chunksEmbedded: 0, chunksReused: 0, deleted: 0 };
  let pendingRows = [];
  let pendingDeletes = [];

  const flushDeletes = async () => {
    if (!table || !pendingDeletes.length) return;
    const list = pendingDeletes.map((p) => `'${esc(p)}'`).join(',');
    await table.delete(`path IN (${list})`);
    pendingDeletes = [];
  };
  const flushRows = async () => {
    if (!pendingRows.length) return;
    await flushDeletes();
    if (!table) table = await createTable(pendingRows);
    else await table.add(pendingRows);
    pendingRows = [];
  };

  for await (const doc of allDocs(names)) {
    seenPaths.add(doc.path);
    if (existing.get(doc.path) === doc.fileHash) {
      stats.skipped++;
      continue;
    }

    // Reuse embeddings for unchanged chunk texts within a changed doc.
    const reuse = new Map();
    if (table && existing.has(doc.path)) {
      try {
        const old = await table.query()
          .where(`path = '${esc(doc.path)}'`)
          .select(['text_hash', 'vector'])
          .toArray();
        for (const r of old) reuse.set(r.text_hash, Array.from(r.vector));
      } catch { /* fine — just re-embed */ }
      pendingDeletes.push(doc.path);
    }

    const rows = doc.chunks.map((text, i) => ({
      id: `${doc.path}#${i}`,
      source: doc.source,
      path: doc.path,
      title: doc.title ?? doc.path,
      chunk: i,
      text,
      text_hash: sha256(text),
      file_hash: doc.fileHash,
      mtime: doc.mtime ?? 0,
      fn_addr: doc.fnAddr ?? '',
      addrs: extractAddrs(text),
      meta: doc.meta ?? '',
      vector: null,
    }));

    const toEmbed = rows.filter((r) => {
      const v = reuse.get(r.text_hash);
      if (v) { r.vector = v; stats.chunksReused++; return false; }
      return true;
    });
    if (toEmbed.length) {
      const vecs = await embedPassages(toEmbed.map((r) => r.text));
      toEmbed.forEach((r, i) => { r.vector = Array.from(vecs[i]); });
      stats.chunksEmbedded += toEmbed.length;
    }
    pendingRows.push(...rows);
    stats.docs++;
    if (pendingRows.length >= 800 || pendingDeletes.length >= 200) await flushRows();
    if (stats.docs % 200 === 0)
      log(`[ingest] ${stats.docs} docs updated, ${stats.skipped} unchanged, ${stats.chunksEmbedded} chunks embedded (last: ${doc.path})`);
  }
  await flushRows();
  await flushDeletes();

  // Remove rows for docs that no longer exist in the walked sources.
  if (table) {
    const stale = [...existing.keys()].filter((p) => !seenPaths.has(p));
    for (let i = 0; i < stale.length; i += 200) {
      const list = stale.slice(i, i + 200).map((p) => `'${esc(p)}'`).join(',');
      await table.delete(`path IN (${list})`);
    }
    stats.deleted = stale.length;
  }

  // (Re)build the BM25 full-text index so exact tokens (FUN_..., hashes) hit.
  if (table && (stats.docs || stats.deleted)) {
    try {
      await table.createIndex('text', { config: lancedb.Index.fts(), replace: true });
      log('[ingest] FTS index rebuilt');
    } catch (e) {
      log(`[ingest] FTS index failed (vector-only search still works): ${e.message}`);
    }
    try { await table.optimize(); } catch { /* older SDKs */ }
  }
  return stats;
}

// CLI entry
const { pathToFileURL } = await import('node:url');
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const sources = argVal('--sources')?.split(',').map((s) => s.trim()).filter(Boolean);
  const t0 = Date.now();
  ingest({ sources, full: argv.includes('--full') })
    .then((s) => {
      console.error(`[ingest] done in ${((Date.now() - t0) / 1000).toFixed(1)}s: ${JSON.stringify(s)}`);
    })
    .catch((e) => { console.error(e); process.exit(1); });
}
