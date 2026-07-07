import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));

/** Repo root = tools/corpus_mcp/src -> up three. */
export const REPO_ROOT = path.resolve(here, '..', '..', '..');

/** LanceDB storage location (gitignored). Override with CORPUS_DB. */
export const DB_PATH =
  process.env.CORPUS_DB || path.join(REPO_ROOT, 'storage', 'corpus_lancedb');

export const TABLE_NAME = 'corpus';

/** Claude Code encodes a project cwd into a directory name by replacing
 *  path separators / colons with '-' (drive letter lowercased). */
function claudeProjectDir(root) {
  const key = (root[0].toLowerCase() + root.slice(1)).replace(/[:\\/]/g, '-');
  return path.join(os.homedir(), '.claude', 'projects', key);
}

/** Where conversation transcripts + memory live. Override with CORPUS_TRANSCRIPTS_DIR. */
export const TRANSCRIPTS_DIR =
  process.env.CORPUS_TRANSCRIPTS_DIR || claudeProjectDir(REPO_ROOT);

export const MEMORY_DIR = path.join(TRANSCRIPTS_DIR, 'memory');

/** Embedding model (transformers.js, runs locally on CPU; ~34MB quantized download on first use). */
export const EMBED_MODEL = 'Xenova/bge-small-en-v1.5';
export const EMBED_DIM = 384;
/** bge models want this prefix on QUERIES only (not passages). */
export const QUERY_PREFIX =
  'Represent this sentence for searching relevant passages: ';

/** Chunking targets (characters). */
export const CHUNK_TARGET = 1400;
export const CHUNK_OVERLAP = 150;
export const CONVO_WINDOW = 1800;

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
    excludeDirs: ['corpus_mcp/node_modules', 'external', 'x32dbg', 'jdk21', 'ghidra_12.1_PUBLIC', 'unrar', 'ffmpeg', 'bin', 'target', '__pycache__', '.venv', 'node_modules'],
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
export const GHIDRA_DUMP = 'output/_ghidra/mercs2_unpacked.exe_decomp.txt';

/** Skip any file bigger than this (bytes) for plain file sources. */
export const MAX_FILE_BYTES = 4 * 1024 * 1024;
