import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// End-to-end smoke test: build a tiny throwaway repo, ingest the `doc` + `ghidra`
// sources into a temp LanceDB, and exercise search / xref / getDoc / coverage /
// callgraph / translate against it. This is the real embedding pipeline, so it needs
// the transformers.js model (~34MB, downloaded + cached on first run). An ingest
// failure (including a model that cannot be loaded) fails the suite. Set
// CORPUS_SKIP_INTEGRATION=1 to opt out of the whole file explicitly.

const here = path.dirname(fileURLToPath(import.meta.url));
const skip = process.env.CORPUS_SKIP_INTEGRATION === '1';
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-e2e-'));
const exportsDir = path.join(root, 'ghidra_exports');

// Point the whole config at the throwaway tree BEFORE importing config-backed
// modules (env is read at module-eval time -> dynamic import below).
process.env.CORPUS_ENV_FILE = path.join(root, 'no.env');
process.env.CORPUS_REPO_ROOT = root;
process.env.CORPUS_DB = path.join(root, 'db');
process.env.CORPUS_TRANSCRIPTS_DIR = path.join(root, 'no-transcripts');
process.env.CORPUS_GHIDRA_EXPORTS = 'ghidra_exports';
process.env.CORPUS_GHIDRA_IMAGES = 'ghidra_exports/images.tsv';

let ingest, search, xref, getDoc, coverage, callgraph, translate, stats, status, clearCaches, embedPassages, connect;

before(async () => {
  fs.mkdirSync(path.join(root, 'docs'), { recursive: true });
  fs.writeFileSync(
    path.join(root, 'docs', 'alpha.md'),
    '# Alpha\n\nThe wavelet skeletal animation decoder is implemented in FUN_00478120 ' +
      'and numerically matches the live capture across all test clips.\n',
  );
  fs.writeFileSync(
    path.join(root, 'docs', 'beta.md'),
    '# Beta\n\nWorld streaming decides per-entity hibernation distances from the ' +
      'HibernationControl component; residency drives the LOD budget.\n',
  );
  // Two images (pc-v1, pc-v10) + a variant (pc-v10-de). FUN_00478120 is named by alpha.md
  // above -> "covered" on pc-v1; its neighbours aren't.
  fs.cpSync(path.join(here, 'fixtures', 'ghidra'), exportsDir, { recursive: true });

  ({ ingest } = await import('../src/ingest.js'));
  ({ search, xref, getDoc, coverage, callgraph, translate, stats, status, clearCaches } = await import('../src/search.js'));
  ({ embedPassages } = await import('../src/embed.js'));
  ({ connect } = await import('../src/db.js'));

  if (skip) return;
  const s = await ingest({ sources: ['doc', 'ghidra'], log: () => {} });
  assert.equal(s.docs, 8, '2 docs + 6 ghidra functions ingested');
});

after(() => fs.rmSync(root, { recursive: true, force: true }));

const T = { timeout: 180_000 };

test('search finds the semantically relevant doc', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const res = await search({ query: 'wavelet animation decoding', k: 3 });
  assert.ok(res.length > 0);
  assert.equal(res[0].path, 'docs/alpha.md');
  assert.ok(res[0].score > 0);
});

test('search matches an exact engine token via full-text', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const res = await search({ query: 'FUN_00478120', k: 5 });
  // Exact token hits both the doc that names it and the decompiled function.
  assert.ok(res.some((r) => r.path === 'docs/alpha.md' || r.path === 'ghidra/pc-v1/0x00478120'));
});

test('xref resolves an address regardless of spelling, across every image', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const r = await xref({ ref: '0x478120' }); // different spelling than the doc
  assert.equal(r.addr, '0x00478120');
  assert.ok(r.bySource.doc?.some((c) => c.path === 'docs/alpha.md' && c.image_id === ''));
  const ghidraPaths = r.bySource.ghidra.map((c) => c.path).sort();
  assert.deepEqual(ghidraPaths, [
    'ghidra/pc-v1/0x00478000', // callee
    'ghidra/pc-v1/0x00478120', // itself
    'ghidra/pc-v1/0x00478200', // caller
    'ghidra/pc-v1/0x00478300', // caller
    'ghidra/pc-v10/0x00479120', // translation
  ]);
  for (const c of r.bySource.ghidra) assert.equal(c.image_id, c.path.split('/')[1], 'every hit reports its image_id');
});

test('xref with image keeps only that image (exact token, variants resolve)', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const v1 = await xref({ ref: '0x478120', image: 'pc-v1' });
  // 'pc-v1' is a substring of 'pc-v10': a substring match would leak pc-v10's row in here.
  assert.deepEqual(Object.keys(v1.bySource), ['ghidra']);
  assert.ok(v1.bySource.ghidra.every((c) => c.image_id === 'pc-v1'));
  assert.equal(v1.mentions, 4);

  const de = await xref({ ref: 'FUN_00478120', image: 'pc-v10-de' });
  assert.deepEqual(de.bySource.ghidra.map((c) => [c.path, c.image_id]), [['ghidra/pc-v10/0x00479120', 'pc-v10']]);

  await assert.rejects(() => xref({ ref: '0x478120', image: 'pc-v2' }), /image 'pc-v2' has no ghidra rows in the index \(indexed images: pc-v1, pc-v10, pc-v10-de\)/);
});

test('getDoc returns the chunks of one document', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const chunks = await getDoc({ path: 'docs/beta.md' });
  assert.ok(chunks.length >= 1);
  assert.ok(chunks[0].text.includes('hibernation distances'));
  const fn = await getDoc({ path: 'ghidra/pc-v1/0x00478200' });
  assert.equal(fn.length, 1);
  assert.equal(fn[0].image_id, 'pc-v1');
  assert.equal(fn[0].va, '0x00478200');
  assert.ok(fn[0].text.includes('decompile failed: Decompiler process timed out after 60 seconds'));
});

test('duplicate names in one image are both indexed', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const a = await getDoc({ path: 'ghidra/pc-v1/0x00478200' });
  const b = await getDoc({ path: 'ghidra/pc-v1/0x00478300' });
  assert.match(a[0].title, /^__break @0x00478200 \[pc-v1\]$/);
  assert.match(b[0].title, /^__break @0x00478300 \[pc-v1\]$/);
});

test('coverage is per image and requires one', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const c = await coverage({ image: 'pc-v1', top: 10 });
  assert.equal(c.totalFunctions, 4);
  // FUN_00478120 is named by alpha.md; the other three are not.
  assert.equal(c.covered, 1);
  assert.ok(c.topCovered.some((f) => f.addr === '0x00478120' && f.mentionedIn.includes('doc')));
  assert.ok(c.topUncovered.some((f) => f.addr === '0x00478200'));

  const v10 = await coverage({ image: 'pc-v10-de' });
  assert.equal(v10.codeImage, 'pc-v10');
  assert.equal(v10.totalFunctions, 2);
  assert.equal(v10.covered, 0);

  await assert.rejects(() => coverage({ top: 10 }), /`image` is required/);
});

test('coverage supports prefix filtering and caller sorting', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const byCallers = await coverage({ image: 'pc-v1', sort: 'callers', prefix: '0047' });
  assert.equal(byCallers.totalFunctions, 4); // all four start 0047
  const empty = await coverage({ image: 'pc-v1', prefix: 'ffff' }); // matches nothing
  assert.equal(empty.totalFunctions, 0);
  assert.equal(empty.coveredPct, 0);
});

test('callgraph walks one image, annotating documented nodes', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const g = await callgraph({ image: 'pc-v1', ref: 'FUN_00478120', direction: 'both', depth: 1 });
  assert.equal(g.root, '0x00478120');
  assert.deepEqual(g.nodes.map((n) => n.addr).sort(), ['0x00478000', '0x00478120', '0x00478200', '0x00478300']);
  const rootNode = g.nodes.find((n) => n.addr === '0x00478120');
  assert.ok(rootNode.documentedIn.includes('doc'), 'root annotated as documented');
  assert.equal(rootNode.callees, 2, 'only VA callees are graph edges');
  assert.ok(g.edges.includes('0x00478120 -> 0x00478200'));
  assert.ok(g.edges.includes('0x00478000 -> 0x00478120'));

  const v10 = await callgraph({ image: 'pc-v10-de', ref: '0x479120', direction: 'callees', depth: 1 });
  assert.equal(v10.codeImage, 'pc-v10');
  assert.deepEqual(v10.nodes.map((n) => n.addr).sort(), ['0x00479120', '0x00479200']);
});

test('callgraph rejects a function of another image, a missing image, and bad refs', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  await assert.rejects(() => callgraph({ image: 'pc-v10', ref: '0x478120' }), /0x00478120 is not a decompiled function of image pc-v10/);
  await assert.rejects(() => callgraph({ ref: '0x478120' }), /`image` is required/);
  await assert.rejects(() => callgraph({ image: 'pc-v1', ref: 'zzz' }), /could not parse/);
});

test('callgraph walks a single direction when asked', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const callees = await callgraph({ image: 'pc-v1', ref: '0x478120', direction: 'callees', depth: 1 });
  assert.ok(callees.nodes.some((n) => n.addr === '0x00478200'));
  assert.ok(!callees.nodes.some((n) => n.addr === '0x00478000'), 'callers excluded');

  const callers = await callgraph({ image: 'pc-v1', ref: '0x478120', direction: 'callers', depth: 1 });
  assert.ok(callers.nodes.some((n) => n.addr === '0x00478000'));
  assert.ok(!callers.nodes.some((n) => n.addr === '0x00478200'), 'callees excluded');
});

test('translate returns names and translations from the indexed row', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const r = await translate({ image: 'pc-v1', va: 'FUN_00478120' });
  assert.equal(r.path, 'ghidra/pc-v1/0x00478120');
  assert.deepEqual(r.names.map((n) => n.name), ['FUN_00478120', 'HudMinimap::Draw']);
  assert.deepEqual(r.translations, [{ image: 'pc-v10', va: '0x00479120', direct: true, answering_paths: 3, paths: 5 }]);
  assert.deepEqual(r.graph_images, ['pc-v1', 'pc-v10']);

  const toVariant = await translate({ image: 'pc-v1', va: '0x478120', to: 'pc-v10-de' });
  assert.equal(toVariant.toCodeImage, 'pc-v10');
  assert.equal(toVariant.translations.length, 1);
  const toSelf = await translate({ image: 'pc-v1', va: '0x478120', to: 'pc-v1' });
  assert.deepEqual(toSelf.translations, []);

  const back = await translate({ image: 'pc-v10-de', va: '0x479200' });
  assert.deepEqual(back.translations, [{ image: 'pc-v1', va: '0x00478200', direct: false, answering_paths: 1, paths: 2 }]);

  await assert.rejects(() => translate({ image: 'pc-v1', va: '0x479120' }), /0x00479120 is not a function of image pc-v1/);
  await assert.rejects(() => translate({ image: 'pc-v1', va: '0x478120', to: 'x360-zz' }), /image 'x360-zz' has no ghidra rows/);
});

test('stats reports per-source chunk/doc counts', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const s = await stats();
  assert.equal(s.indexed, true);
  assert.equal(s.bySource.doc.docs, 2);
  assert.equal(s.bySource.ghidra.docs, 6);
  assert.ok(s.totalChunks >= 8);
});

test('search honours the sources and path_prefix filters', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const onlyDocs = await search({ query: 'FUN_00478120', k: 8, sources: ['doc'] });
  assert.ok(onlyDocs.length > 0);
  assert.ok(onlyDocs.every((r) => r.source === 'doc'), 'sources filter applied');

  const prefixed = await search({ query: 'wavelet', k: 8, pathPrefix: 'docs/' });
  assert.ok(prefixed.length > 0);
  assert.ok(prefixed.every((r) => r.path.startsWith('docs/')), 'path_prefix filter applied');
});

test('xref rejects an unparseable reference', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  await assert.rejects(() => xref({ ref: 'not-an-address' }), /could not parse an address/);
});

test('getDoc windows around a chunk when given one', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const win = await getDoc({ path: 'ghidra/pc-v1/0x00478120', chunk: 0, context: 0 });
  assert.equal(win.length, 1);
  assert.equal(win[0].chunk, 0);
});

test('embedPassages substitutes a space for empty passages', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const [v] = await embedPassages(['']); // exercises the `|| ' '` guard
  assert.equal(v.length, 384);
});

// Mutates the tree + DB to exercise incremental re-ingest.
test('re-ingest skips unchanged, picks up new, and deletes vanished docs', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  // Nothing changed -> everything skipped, no embeddings.
  const noop = await ingest({ sources: ['doc', 'ghidra'], log: () => {} });
  assert.equal(noop.docs, 0);
  assert.equal(noop.skipped, 8);
  assert.equal(noop.chunksEmbedded, 0);

  // A two-chunk doc, then a change confined to the first chunk: the unchanged
  // second chunk's embedding must be reused, not recomputed.
  const p1 = 'streaming residency and budget detail sentence number. '.repeat(30);
  const p2 = 'hibernation distance detail sentence for the loader here. '.repeat(30);
  const delta = path.join(root, 'docs', 'delta.md');
  fs.writeFileSync(delta, `${p1}\n\n${p2}\n`);
  const seeded = await ingest({ sources: ['doc'], log: () => {} });
  assert.equal(seeded.docs, 1);
  assert.ok(seeded.chunksEmbedded >= 2, 'delta seeded as multiple chunks');

  fs.writeFileSync(delta, `CHANGED-HEAD ${p1}\n\n${p2}\n`); // only the first chunk differs
  const reingested = await ingest({ sources: ['doc'], log: () => {} });
  assert.equal(reingested.docs, 1);
  assert.ok(reingested.chunksReused >= 1, 'unchanged chunk embedding reused');
  assert.ok(reingested.chunksEmbedded >= 1, 'changed chunk re-embedded');

  // Add a doc -> one new doc ingested, delta unchanged so skipped.
  const gamma = path.join(root, 'docs', 'gamma.md');
  fs.writeFileSync(gamma, '# Gamma\n\nA freshly added note about the terrain loader.\n');
  const added = await ingest({ sources: ['doc'], log: () => {} });
  assert.equal(added.docs, 1);
  clearCaches();
  assert.ok((await getDoc({ path: 'docs/gamma.md' })).length >= 1);

  // Remove gamma + delta together -> both stale rows deleted on the next pass.
  fs.rmSync(gamma);
  fs.rmSync(delta);
  const removed = await ingest({ sources: ['doc'], log: () => {} });
  assert.equal(removed.deleted, 2); // gamma + delta
  clearCaches();
  assert.deepEqual(await getDoc({ path: 'docs/gamma.md' }), []);

  // --full reprocesses every doc regardless of file hash (nothing skipped);
  // identical chunk text still reuses its stored embedding.
  const full = await ingest({ sources: ['doc'], full: true, log: () => {} });
  assert.equal(full.skipped, 0, 'full mode skips nothing');
  assert.ok(full.docs >= 2, 'full mode reprocesses alpha + beta');
  assert.ok(full.chunksReused >= 2, 'unchanged chunk text reuses its embedding');
});

test('an image with no export files is not indexed, and status lists it with its variants', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  const hold = path.join(root, 'held');
  fs.mkdirSync(hold);
  const files = ['pc-v10.functions.jsonl', 'pc-v10.annotate.jsonl'];
  for (const f of files) fs.renameSync(path.join(exportsDir, f), path.join(hold, f));
  try {
    const lines = [];
    const s = await ingest({ sources: ['ghidra'], log: (m) => lines.push(m) });
    assert.equal(s.deleted, 2, "pc-v10's two functions leave the index with its export");
    assert.ok(lines.some((m) => m.includes('not exported, so not indexed: pc-v10 (+ pc-v10-de)')), lines.join('\n'));
    clearCaches();
    assert.equal((await stats()).bySource.ghidra.docs, 4);
    const st = await status({ force: true });
    assert.deepEqual(st.sources.ghidra.images.notExported, [{ image: 'pc-v10', variants: ['pc-v10-de'] }]);
    assert.deepEqual(Object.keys(st.sources.ghidra.images.indexed), ['pc-v1']);
  } finally {
    for (const f of files) fs.renameSync(path.join(hold, f), path.join(exportsDir, f));
  }
  // Exported again but not yet indexed: stale until the next ingest.
  clearCaches();
  const st = await status({ force: true });
  assert.deepEqual(st.sources.ghidra.images.exportedNotIndexed, ['pc-v10']);
  assert.equal(st.stale, true);
  const back = await ingest({ sources: ['ghidra'], log: () => {} });
  assert.equal(back.docs, 2);
  clearCaches();
  assert.deepEqual((await status({ force: true })).sources.ghidra.images.exportedNotIndexed, []);
});

// Runs last: it replaces the table.
test('a table with an older row shape is migrated in place, keeping every row and vector', T, async (t) => {
  if (skip) return t.skip('CORPUS_SKIP_INTEGRATION=1');
  // Recreate the pre-multi-image table: the current non-ghidra rows (vectors and all) in the old
  // shape (fn_addr, no image columns), plus one ghidra row keyed by name as the old source wrote it.
  const db = await connect();
  const current = await (await db.openTable('corpus')).query().toArray();
  const oldRows = current.filter((r) => r.source !== 'ghidra').map((r) => ({
    id: r.id, source: r.source, path: r.path, title: r.title, chunk: r.chunk, text: r.text,
    text_hash: r.text_hash, file_hash: r.file_hash, mtime: r.mtime, fn_addr: '', addrs: r.addrs, meta: r.meta,
    vector: Array.from(r.vector),
  }));
  oldRows.push({
    id: 'ghidra/FUN_00478120#0', source: 'ghidra', path: 'ghidra/FUN_00478120', title: 'FUN_00478120', chunk: 0,
    text: 'old', text_hash: 'h', file_hash: 'f', mtime: 0, fn_addr: '00478120', addrs: '00478120', meta: '{}',
    vector: Array(384).fill(0),
  });
  await db.dropTable('corpus');
  await db.createTable('corpus', oldRows, { mode: 'create' });
  clearCaches();
  await assert.rejects(() => xref({ ref: '0x478120' }), /missing: image_id, image_sha256, va, images; extra: fn_addr\).*it migrates the columns in place/);

  const lines = [];
  const docs = await ingest({ sources: ['doc'], log: (m) => lines.push(m) });
  assert.ok(lines.some((m) => m.includes('migrated table columns in place: added [image_id, image_sha256, va, images], dropped [fn_addr]')), lines.join('\n'));
  assert.equal(docs.skipped, 2, 'the doc rows survive the migration unchanged');
  assert.equal(docs.chunksEmbedded, 0, 'no doc row is re-embedded');

  // The ghidra source replaces the old name-keyed row with the per-image rows.
  const gh = await ingest({ sources: ['ghidra'], log: () => {} });
  assert.equal(gh.docs, 6);
  assert.equal(gh.deleted, 1);
  clearCaches();
  const s = await stats();
  assert.equal(s.bySource.ghidra.docs, 6);
  assert.equal(s.bySource.doc.docs, 2);
  assert.deepEqual(await getDoc({ path: 'ghidra/FUN_00478120' }), []);

  // The migrated table takes new rows.
  const gamma = path.join(root, 'docs', 'gamma.md');
  fs.writeFileSync(gamma, '# Gamma\n\nA new note written after the migration.\n');
  try {
    const added = await ingest({ sources: ['doc'], log: () => {} });
    assert.equal(added.docs, 1);
    clearCaches();
    assert.equal((await getDoc({ path: 'docs/gamma.md' })).length, 1);
  } finally {
    fs.rmSync(gamma);
  }
});
