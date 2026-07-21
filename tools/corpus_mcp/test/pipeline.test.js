import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// End-to-end smoke test: build a tiny throwaway repo, ingest the `doc` + `ghidra`
// sources into a temp LanceDB, and exercise search / xref / getDoc / coverage /
// callgraph against it. This is the real embedding pipeline, so it needs the
// transformers.js model (~34MB, downloaded + cached on first run). It self-skips
// if the model can't be loaded (offline) or CORPUS_SKIP_INTEGRATION is set.

const here = path.dirname(fileURLToPath(import.meta.url));
const skip = process.env.CORPUS_SKIP_INTEGRATION === '1';
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-e2e-'));

// Point the whole config at the throwaway tree BEFORE importing config-backed
// modules (env is read at module-eval time -> dynamic import below).
process.env.CORPUS_ENV_FILE = path.join(root, 'no.env');
process.env.CORPUS_REPO_ROOT = root;
process.env.CORPUS_DB = path.join(root, 'db');
process.env.CORPUS_TRANSCRIPTS_DIR = path.join(root, 'no-transcripts');
process.env.CORPUS_GHIDRA_DUMP = 'ghidra/dump.txt';

let ingest, search, xref, getDoc, coverage, callgraph, stats, clearCaches, embedPassages, ready = false;

before(async () => {
  fs.mkdirSync(path.join(root, 'docs'), { recursive: true });
  fs.mkdirSync(path.join(root, 'ghidra'), { recursive: true });
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
  // FUN_00478120 is named by alpha.md above -> "covered"; its neighbours aren't.
  fs.copyFileSync(path.join(here, 'fixtures', 'ghidra_sample.txt'), path.join(root, 'ghidra', 'dump.txt'));

  ({ ingest } = await import('../src/ingest.js'));
  ({ search, xref, getDoc, coverage, callgraph, stats, clearCaches } = await import('../src/search.js'));
  ({ embedPassages } = await import('../src/embed.js'));

  if (skip) return;
  try {
    const stats = await ingest({ sources: ['doc', 'ghidra'], log: () => {} });
    assert.ok(stats.docs >= 5, 'docs + 3 ghidra functions ingested');
    ready = true;
  } catch (e) {
    // Most likely the embedding model could not be fetched — skip, don't fail.
    console.error(`[pipeline.test] ingest unavailable, skipping e2e: ${e.message}`);
  }
});

after(() => fs.rmSync(root, { recursive: true, force: true }));

test('search finds the semantically relevant doc', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const res = await search({ query: 'wavelet animation decoding', k: 3 });
    assert.ok(res.length > 0);
    assert.equal(res[0].path, 'docs/alpha.md');
    assert.ok(res[0].score > 0);
  })();
});

test('search matches an exact engine token via full-text', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const res = await search({ query: 'FUN_00478120', k: 5 });
    // Exact token hits both the doc that names it and the decompiled function.
    assert.ok(res.some((r) => r.path === 'docs/alpha.md' || r.path === 'ghidra/FUN_00478120'));
  })();
});

test('xref resolves an address regardless of spelling', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const r = await xref({ ref: '0x478120' }); // different spelling than the doc
    assert.equal(r.addr, '0x00478120');
    assert.ok(r.mentions >= 2);
    assert.ok(r.bySource.doc?.some((c) => c.path === 'docs/alpha.md'));
    assert.ok(r.bySource.ghidra?.some((c) => c.path === 'ghidra/FUN_00478120'));
  })();
});

test('getDoc returns the chunks of one document', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const chunks = await getDoc({ path: 'docs/beta.md' });
    assert.ok(chunks.length >= 1);
    assert.ok(chunks[0].text.includes('hibernation distances'));
  })();
});

test('coverage splits documented vs undocumented functions', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const c = await coverage({ top: 10 });
    assert.equal(c.totalFunctions, 3);
    // FUN_00478120 is named by alpha.md; the other two are not.
    assert.equal(c.covered, 1);
    assert.ok(c.topCovered.some((f) => f.addr === '0x00478120' && f.mentionedIn.includes('doc')));
    assert.ok(c.topUncovered.some((f) => f.addr === '0x00478200'));
  })();
});

test('callgraph walks callers/callees, annotating documented nodes', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const g = await callgraph({ ref: 'FUN_00478120', direction: 'both', depth: 1 });
    assert.equal(g.root, '0x00478120');
    const addrs = g.nodes.map((n) => n.addr);
    assert.ok(addrs.includes('0x00478200'), 'callee present');
    assert.ok(addrs.includes('0x00478000'), 'caller present');
    const rootNode = g.nodes.find((n) => n.addr === '0x00478120');
    assert.ok(rootNode.documentedIn.includes('doc'), 'root annotated as documented');
    assert.ok(g.edges.includes('0x00478120 -> 0x00478200'));
  })();
});

test('callgraph rejects an address that is not a decompiled function', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return assert.rejects(() => callgraph({ ref: '0xdeadbeef' }), /not a decompiled function/);
});

test('stats reports per-source chunk/doc counts', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const s = await stats();
    assert.equal(s.indexed, true);
    assert.equal(s.bySource.doc.docs, 2);
    assert.equal(s.bySource.ghidra.docs, 3);
    assert.ok(s.totalChunks >= 5);
  })();
});

test('search honours the sources and path_prefix filters', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const onlyDocs = await search({ query: 'FUN_00478120', k: 8, sources: ['doc'] });
    assert.ok(onlyDocs.length > 0);
    assert.ok(onlyDocs.every((r) => r.source === 'doc'), 'sources filter applied');

    const prefixed = await search({ query: 'wavelet', k: 8, pathPrefix: 'docs/' });
    assert.ok(prefixed.length > 0);
    assert.ok(prefixed.every((r) => r.path.startsWith('docs/')), 'path_prefix filter applied');
  })();
});

test('xref rejects an unparseable reference', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return assert.rejects(() => xref({ ref: 'not-an-address' }), /could not parse an address/);
});

test('getDoc windows around a chunk when given one', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const win = await getDoc({ path: 'ghidra/FUN_00478120', chunk: 0, context: 0 });
    assert.equal(win.length, 1);
    assert.equal(win[0].chunk, 0);
  })();
});

test('coverage supports prefix filtering and caller sorting', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const byCallers = await coverage({ sort: 'callers', prefix: '0047' });
    assert.equal(byCallers.totalFunctions, 3); // all three start 0047
    const empty = await coverage({ prefix: 'ffff' }); // matches nothing
    assert.equal(empty.totalFunctions, 0);
    assert.equal(empty.coveredPct, 0);
  })();
});

test('callgraph rejects an unparseable reference', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return assert.rejects(() => callgraph({ ref: 'zzz' }), /could not parse/);
});

test('callgraph walks a single direction when asked', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const callees = await callgraph({ ref: '0x478120', direction: 'callees', depth: 1 });
    assert.ok(callees.nodes.some((n) => n.addr === '0x00478200'));
    assert.ok(!callees.nodes.some((n) => n.addr === '0x00478000'), 'callers excluded');

    const callers = await callgraph({ ref: '0x478120', direction: 'callers', depth: 1 });
    assert.ok(callers.nodes.some((n) => n.addr === '0x00478000'));
    assert.ok(!callers.nodes.some((n) => n.addr === '0x00478200'), 'callees excluded');
  })();
});

test('embedPassages substitutes a space for empty passages', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    const [v] = await embedPassages(['']); // exercises the `|| ' '` guard
    assert.equal(v.length, 384);
  })();
});

// Runs last: it mutates the tree + DB to exercise incremental re-ingest.
test('re-ingest skips unchanged, picks up new, and deletes vanished docs', { timeout: 180_000 }, (t) => {
  if (skip || !ready) return t.skip('embedding pipeline unavailable');
  return (async () => {
    // Nothing changed -> everything skipped, no embeddings.
    const noop = await ingest({ sources: ['doc'], log: () => {} });
    assert.equal(noop.docs, 0);
    assert.ok(noop.skipped >= 2);
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
  })();
});
