import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import { loadEnvFile } from './env.js';

const here = path.dirname(fileURLToPath(import.meta.url));

/** Package root = tools/corpus_mcp/src -> up one. */
const PKG_ROOT = path.resolve(here, '..');

// Load `.env` before reading any config. A real process env var always wins
// over the file (loadEnvFile never clobbers an already-set variable). Point
// elsewhere with CORPUS_ENV_FILE; that one must be a real env var (chicken/egg).
loadEnvFile(process.env.CORPUS_ENV_FILE || path.join(PKG_ROOT, '.env'));

/** Read a string env var, falling back to `dflt`. */
function str(name, dflt) {
  const v = process.env[name];
  return v === undefined || v === '' ? dflt : v;
}
/** Read a numeric env var; throws on a non-numeric override so typos surface. */
function num(name, dflt) {
  const v = process.env[name];
  if (v === undefined || v === '') return dflt;
  const n = Number(v);
  if (!Number.isFinite(n)) throw new Error(`${name} must be a number, got '${v}'`);
  return n;
}

/** Repo root = three up from src, or CORPUS_REPO_ROOT to index another tree. */
export const REPO_ROOT = path.resolve(str('CORPUS_REPO_ROOT', path.resolve(here, '..', '..', '..')));

/** LanceDB storage location (gitignored). Override with CORPUS_DB. */
export const DB_PATH =
  str('CORPUS_DB', null) || path.join(REPO_ROOT, 'storage', 'corpus_lancedb');

export const TABLE_NAME = str('CORPUS_TABLE', 'corpus');

/** Claude Code encodes a project cwd into a directory name by replacing
 *  path separators / colons with '-' (drive letter lowercased). */
function claudeProjectDir(root) {
  const key = (root[0].toLowerCase() + root.slice(1)).replace(/[:\\/]/g, '-');
  return path.join(os.homedir(), '.claude', 'projects', key);
}

/** Where conversation transcripts + memory live. Override with CORPUS_TRANSCRIPTS_DIR. */
export const TRANSCRIPTS_DIR =
  str('CORPUS_TRANSCRIPTS_DIR', null) || claudeProjectDir(REPO_ROOT);

export const MEMORY_DIR =
  str('CORPUS_MEMORY_DIR', null) || path.join(TRANSCRIPTS_DIR, 'memory');

/** Embedding model (transformers.js, runs locally on CPU; ~34MB quantized download on first use). */
export const EMBED_MODEL = str('CORPUS_EMBED_MODEL', 'Xenova/bge-small-en-v1.5');
export const EMBED_DIM = num('CORPUS_EMBED_DIM', 384);
/** bge models want this prefix on QUERIES only (not passages). */
export const QUERY_PREFIX = str(
  'CORPUS_QUERY_PREFIX',
  'Represent this sentence for searching relevant passages: ',
);

/** Chunking targets (characters). */
export const CHUNK_TARGET = num('CORPUS_CHUNK_TARGET', 1400);
export const CHUNK_OVERLAP = num('CORPUS_CHUNK_OVERLAP', 150);
export const CONVO_WINDOW = num('CORPUS_CONVO_WINDOW', 1800);

/** The edges of the corpus: every source the index knows how to walk.
 *  Everything is repo-root-relative except conversations/memory. */
export const SOURCES = {
  // Written knowledge: research docs, specs, format docs, decompiled Lua corpus.
  doc: {
    dirs: ['docs'],
    exts: ['.md', '.lua', '.json', '.ini', '.cfg', '.txt'],
  },
  // Persistent Claude memory (one fact per file).
  memory: { special: 'memory' },
  // Native mods (ASI sources).
  mod: {
    dirs: ['mods'],
    exts: ['.c', '.h', '.cpp', '.md', '.def', '.mk'],
    extraFiles: [],
  },
  // Tooling: python probes, rust workspace, shell scripts, annotations.
  tool: {
    dirs: ['tools', 'scripts', 'coopserver', 'tlsterm'],
    exts: ['.py', '.rs', '.sh', '.md', '.toml'],
    extraFiles: ['scripts/mercs2_annotations.json', 'Makefile'],
    // `worktrees` matters: agent subagents run in `.claude/worktrees/agent-*`, which are full
    // copies of the crate tree. Indexing them duplicated 810 paths / 4,908 chunks (~6% of the
    // corpus) as STALE twins of files that are already indexed at their canonical path — and a
    // twin can outrank the real file. The `project` source already excluded them; `tool` did not.
    excludeDirs: ['corpus_mcp/node_modules', 'external', 'x32dbg', 'jdk21', 'ghidra_12.1_PUBLIC', 'unrar', 'ffmpeg', 'bin', 'target', '__pycache__', '.venv', 'node_modules', 'worktrees'],
  },
  // Top-level project docs + Claude Code project config.
  project: {
    dirs: ['.claude'],
    exts: ['.md'],
    extraFiles: ['AGENTS.md', 'README.md', 'NOTICE'],
    excludeDirs: ['worktrees'],
  },
  // Git commit messages (all branches).
  commit: { special: 'commits' },
  // Ghidra exports of every analysed executable image (PC / X360 / PS3) — one doc per
  // (image, function VA), built from the per-image `<image>.functions.jsonl` (Ghidra exporter)
  // and `<image>.annotate.jsonl` (`exemap annotate`) pair in GHIDRA_EXPORTS.
  ghidra: { special: 'ghidra' },
  // Static Lua API facts. One doc per class/module (chunk 0 carries the full ClassAPI/DataAPI
  // in `meta`), plus one doc per high-cardinality data-record so individual registry entries
  // (tMissionData["PmcCon001"], tStarters["PmcBoss"], …) are query-addressable. Generator walks
  // the shipped Lua tree + the mod corpus and feeds the AST analyzer.
  lua_api: { special: 'lua_api' },
};

/** Directory holding the per-image `<image_id>.functions.jsonl` + `<image_id>.annotate.jsonl`
 *  pairs, relative to REPO_ROOT. */
export const GHIDRA_EXPORTS = str('CORPUS_GHIDRA_EXPORTS', 'output/_ghidra_exports');

/** The image table (one row per executable image; `code_image` marks a regional variant that
 *  shares another image's code), relative to REPO_ROOT. An image with no export pair is listed
 *  as not exported. */
export const GHIDRA_IMAGES = str('CORPUS_GHIDRA_IMAGES', 'tools/wad_simulator/crates/mercs2_exemap/data/images.tsv');

// --- Ghidra bridge (ghidra_bridge.js): one live headless Ghidra per image -------------------
/** The per-image Ghidra project table (scripts/ghidra_projects.tsv), relative to REPO_ROOT. */
export const GHIDRA_PROJECTS = str('CORPUS_GHIDRA_PROJECTS', 'scripts/ghidra_projects.tsv');
/** The machine-local config whose `ghidra_headless` key names analyzeHeadless, relative to REPO_ROOT. */
export const GHIDRA_LOCAL_CONFIG = str('CORPUS_GHIDRA_LOCAL_CONFIG', 'tools/wad_simulator/.mercs2-local.toml');
/** Script directories the bridge's headless run loads (GhidraBridge.java + CallList.java). */
export const GHIDRA_SCRIPTS = str('CORPUS_GHIDRA_SCRIPTS', 'scripts/ghidra_scripts');
/** The ordinal table CallList.java names ordinal imports from. */
export const GHIDRA_ORDINALS = str('CORPUS_GHIDRA_ORDINALS', 'scripts/ghidra_scripts/pe_import_ordinals.tsv');
/** Java heap of each bridge's headless run (analyzeHeadless reads GHIDRA_HEADLESS_MAXMEM). */
export const GHIDRA_BRIDGE_MAXMEM = str('CORPUS_GHIDRA_BRIDGE_MAXMEM', '16G');
/** How long a bridge may take to open its project and start listening (ms). */
export const GHIDRA_BRIDGE_START_MS = num('CORPUS_GHIDRA_BRIDGE_START_MS', 300_000);
/** How long one request may take (ms); a decompile is bounded at 120 s inside the bridge. */
export const GHIDRA_BRIDGE_REQUEST_MS = num('CORPUS_GHIDRA_BRIDGE_REQUEST_MS', 180_000);

/** Skip any file bigger than this (bytes) for plain file sources. */
export const MAX_FILE_BYTES = num('CORPUS_MAX_FILE_BYTES', 4 * 1024 * 1024);
