# corpus_lua_* tool evaluation for PC vs Xbox Lua forensics

**Verdict: unusable as shipped for the Xbox↔PC structural diff.** PC-only, source-form-locked. Evidence below.

## 1. What each tool returns (one invocation each)
- `corpus_lua_api("wifmissionflow")` → structured class record: `inherit_chain` (`["wifmissionflow","MrxMissionFlow"]`), 23 unique `imports`, 11 `methods_defined` with line numbers, flat `data_tables_read` list of `{module, field, line}` triples (~250 entries), one top-level `tables` scalar, 50 walked `inherited_methods`. No constants pool, no proto tree.
- `corpus_lua_callgraph("wifmissionflow")` → BFS over `inherit()` edges only: 2 nodes, 1 edge (`kind:"inherits"`). Not call-level — class hierarchy only.
- `corpus_lua_records("wifmissiondata","tMissionData",{sStarter:"PmcBoss"})` → 7 of 69 records, each a scalar-field dict; nested fields collapse to `"<nested table>"`. Equality predicate only.
- `corpus_lua_xref("WifMissionFlow")` → 16 hits, each `{in_class, where:"imports", module, source_path}`. Works on class names, bare method names, and string literals.
- `corpus_lua_emit_stubs` → wrote stubs covering **349 classes, 4 data modules, 22 record shapes** and a `.luarc.json`.

## 2. PC vs Xbox separability — **NO**
Every returned `source_path` points under `tools/wad_simulator/workshop_data/lua/` — PC decomp. `src/sources.js:352` hard-codes `LUA_ROOTS=['tools/wad_simulator/workshop_data/lua','…/shipments']`; no override. All five tools take a `name` (basename), not a `path`, so no redirect at `docs/mercs2-luacd-xbox/`. Worse: `src/lua_analyzer.js:104` uses `luaparse` and matches `inherit("Name")` as a direct `CallStatement`. Xbox pseudocode writes `L0_1 = inherit; L1_1 = "MrxMissionFlow"; L0_1(L1_1)` — valid Lua, but the register-temporary indirection never matches. Even with LUA_ROOTS extended, Xbox files would return empty `imports`/`inherit_chain`.

## 3. Structural-fingerprint coverage
| Signal | Tool | PC | Xbox |
|---|---|---|---|
| imports / module reads | `api.imports` + `data_tables_read[].module` | yes | **no** |
| call targets (Module.field) | `api.data_tables_read[].field` | yes | no |
| bare-function / `_G[x]` calls | — | **missing** | — |
| constants pool | — | **missing** | — |
| protos / nested closures | — | **missing** | — |
| table shapes / records | `records`, `api.tables` | yes | no |
| call graph | `callgraph` | class-hierarchy only | no |

Bytecode-level signals (consts, upvalues, protos) need direct `.luac` parsing — out of scope for these tools.

## 4. Concrete comparison — `wifmissionflow`
PC side via `corpus_lua_api`; Xbox side via regex `/= (import\|inherit)\s*\n\s*L1_1 = "([^"]+)"/` over `docs/mercs2-luacd-xbox/src/vz/wifmissionflow.lua`:

| Field | PC | Xbox | Equal |
|---|---|---|---|
| inherit_chain | `["MrxMissionFlow"]` | `["MrxMissionFlow"]` | yes |
| import count (unique) | 23 | 23 | yes |
| import set | 23 names | identical 23 names | **set-identical** |

No cross-platform semantic delta on this script — but the Xbox column was produced **manually**, not by the tools.

## 5. Scalability — **NO for cross-platform; YES for PC-only**
- `corpus_status.lua_api.filesOnDisk = 375` (PC); `docs/mercs2-luacd-xbox/` is unscanned.
- `lua_api.chunks = 0` — the tools analyze from disk per call (so they stay live for PC), but Xbox needs **both** a LUA_ROOTS extension and an analyzer rewrite that constant-folds `L<n>=<id>; L<m>="<lit>"; L<n>(L<m>)` back into `<id>("<lit>")` before any tool can see an Xbox file.

**Minimum unblocking work:** (a) add a `root`/platform arg or multi-root list in `src/sources.js`; (b) constant-fold register temporaries in `collectImports`/`collectCalls` (`src/lua_analyzer.js`). Until then, do set-diffs over regex-extracted Xbox imports/calls and corpus_lua_api PC fingerprints, as §4 did.
