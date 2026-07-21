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
  // Claude Code session transcripts (user + assistant text only).
  conversation: { special: 'conversations' },
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
  // Ghidra decompilation of the unpacked PC exe — one row per function,
  // keyed by address, with callers/callees extracted for cross-referencing
  // against the docs corpora (pdb-analysis coverage work).
  ghidra: { special: 'ghidra' },
};

/** Authoritative full-decompilation dump (unpacked exe, 27k functions). */
export const GHIDRA_DUMP = str('CORPUS_GHIDRA_DUMP', 'output/_ghidra/mercs2_unpacked.exe_decomp.txt');

/** Skip any file bigger than this (bytes) for plain file sources. */
export const MAX_FILE_BYTES = num('CORPUS_MAX_FILE_BYTES', 4 * 1024 * 1024);
