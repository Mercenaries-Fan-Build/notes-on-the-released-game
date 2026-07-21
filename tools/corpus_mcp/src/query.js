#!/usr/bin/env node
/** CLI smoke-test for the corpus index.
 *
 *   node src/query.js search "how does the wavelet decoder work" [--sources doc,memory] [-k 5]
 *   node src/query.js xref FUN_00478120
 *   node src/query.js get docs/coordinate_systems.md
 *   node src/query.js coverage [--top 20] [--sort callers]
 *   node src/query.js stats
 *   node src/query.js status        # index freshness: what changed since the last ingest
 */
import { search, xref, getDoc, coverage, callgraph, stats, status } from './search.js';

const [cmd, ...rest] = process.argv.slice(2);
function flag(name, dflt) {
  const i = rest.indexOf(name);
  return i >= 0 ? rest[i + 1] : dflt;
}
const positional = rest.filter((a, i) => !a.startsWith('-') && (i === 0 || !rest[i - 1].startsWith('-')));

const out = (o) => console.log(JSON.stringify(o, null, 2));

try {
  if (cmd === 'search') {
    const res = await search({
      query: positional.join(' '),
      k: Number(flag('-k', 8)),
      sources: flag('--sources')?.split(','),
      pathPrefix: flag('--path'),
    });
    const st = await status().catch(() => null);
    if (st?.stale) console.log(`! index stale: ${st.changedSinceIngest} file(s) changed since the last ingest — ${st.hint}`);
    for (const r of res) {
      // date + unreviewed marker up front: a claim's age and whether anyone checked it are the
      // two things you need BEFORE reading it, not after.
      const tag = r.unreviewed ? ' [UNREVIEWED TRANSCRIPT]' : '';
      console.log(`\n=== ${r.score}  ${r.date ?? '????-??-??'}  [${r.source}]${tag} ${r.path}#${r.chunk}  ${r.title !== r.path ? r.title : ''}`);
      console.log(r.text.slice(0, 500));
    }
  } else if (cmd === 'xref') out(await xref({ ref: positional[0], limit: Number(flag('--limit', 40)) }));
  else if (cmd === 'get') out(await getDoc({ path: positional[0] }));
  else if (cmd === 'coverage') out(await coverage({ top: Number(flag('--top', 30)), sort: flag('--sort', 'size'), prefix: flag('--prefix') }));
  else if (cmd === 'callgraph') out(await callgraph({ ref: positional[0], direction: flag('--dir', 'both'), depth: Number(flag('--depth', 2)), maxNodes: Number(flag('--max', 150)) }));
  else if (cmd === 'stats') out(await stats());
  else if (cmd === 'status') out(await status({ force: true }));
  else console.error('usage: query.js search|xref|get|coverage|stats|status ...');
} catch (e) {
  console.error(e.message);
  process.exit(1);
}
