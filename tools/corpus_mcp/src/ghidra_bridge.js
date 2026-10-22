// One live headless Ghidra per image, kept open between requests: GhidraBridge.java
// (scripts/ghidra_scripts) runs as the only postScript of a headless session on the image's saved
// project and serves newline-delimited JSON over a Unix-domain socket. A bridge starts on the
// first request for its image and runs until stopped (stopBridge, or the server exiting).
//
// The image's project comes from GHIDRA_PROJECTS (scripts/ghidra_projects.tsv); analyzeHeadless
// from the `ghidra_headless` key of GHIDRA_LOCAL_CONFIG. A regional variant (images.tsv
// code_image) is served by its code image's bridge. A Ghidra project is locked by the process that
// opens it, so a project two images share (ps3-v100 and ps3-v103-na) serves one of them at a time,
// and a batch headless run (export, fnsig) cannot open a project a bridge holds — stop the bridge
// first. Every edit is committed and saved by the bridge before it answers, so stopping (or
// killing) a bridge loses no edit.
//
// Every failure is an error naming the image and what happened, with the tail of the bridge's
// log: a bridge that exits or does not start listening in time, a request that times out (the
// bridge is then killed — its state is unknown), an error response.
import fs from 'node:fs';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import { spawn } from 'node:child_process';
import {
  REPO_ROOT, GHIDRA_IMAGES, GHIDRA_PROJECTS, GHIDRA_LOCAL_CONFIG, GHIDRA_SCRIPTS, GHIDRA_ORDINALS,
  GHIDRA_BRIDGE_MAXMEM, GHIDRA_BRIDGE_START_MS, GHIDRA_BRIDGE_REQUEST_MS,
} from './config.js';
import { readImagesTsv } from './sources.js';

const PROJECTS_HEADER = ['image_id', 'project_dir', 'project_name', 'program', 'settings_dir', 'imports', 'code_blocks'];
const LOG_TAIL = 40;
// macOS caps a Unix-domain socket path at 104 bytes (sun_path), Linux at 108.
const MAX_SOCKET_PATH = 103;

/** scripts/ghidra_projects.tsv → Map<image_id, {id, projectDir, projectName, program, settingsDir|null, imports|null, line}>. */
export function readProjectsTsv(file) {
  if (!fs.existsSync(file)) throw new Error(`[ghidra-bridge] ${file}: project table not found`);
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  if (lines[lines.length - 1] === '') lines.pop();
  if (lines[0] !== PROJECTS_HEADER.join('\t')) {
    throw new Error(`[ghidra-bridge] ${file}:1: header is not ${PROJECTS_HEADER.join('\\t')}`);
  }
  const rows = new Map();
  for (let n = 2; n <= lines.length; n++) {
    const f = lines[n - 1].split('\t');
    if (f.length !== PROJECTS_HEADER.length) throw new Error(`[ghidra-bridge] ${file}:${n}: ${f.length} fields, header has ${PROJECTS_HEADER.length}`);
    if (f.some((x) => x === '')) throw new Error(`[ghidra-bridge] ${file}:${n}: an empty field (no value is written '-')`);
    if (rows.has(f[0])) throw new Error(`[ghidra-bridge] ${file}:${n}: image ${f[0]} repeats line ${rows.get(f[0]).line}`);
    rows.set(f[0], {
      id: f[0], projectDir: f[1], projectName: f[2], program: f[3],
      settingsDir: f[4] === '-' ? null : f[4], imports: f[5] === '-' ? null : f[5], line: n,
    });
  }
  return rows;
}

/** The `ghidra_headless = "<path>"` value of the machine-local config (one such line, an executable). */
export function readGhidraHeadless(file) {
  if (!fs.existsSync(file)) throw new Error(`[ghidra-bridge] ${file} does not exist; it must name analyzeHeadless as ghidra_headless = "<path>"`);
  let headless = null;
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    const m = line.match(/^ghidra_headless\s*=\s*"(.*)"\s*$/);
    if (m) {
      if (headless !== null) throw new Error(`[ghidra-bridge] ${file} names ghidra_headless more than once`);
      headless = m[1];
    } else if (line.startsWith('ghidra_headless')) {
      throw new Error(`[ghidra-bridge] ${file}: the ghidra_headless line is not ghidra_headless = "<path>": ${line}`);
    }
  }
  if (headless === null) throw new Error(`[ghidra-bridge] ${file} has no key ghidra_headless`);
  try { fs.accessSync(headless, fs.constants.X_OK); } catch {
    throw new Error(`[ghidra-bridge] ghidra_headless in ${file} is '${headless}', which is not an executable file`);
  }
  return headless;
}

/** The image a request for `image` is served by: itself, or its code image for a regional variant. */
export function servingImage(image, images) {
  const img = images.get(image);
  if (!img) throw new Error(`[ghidra-bridge] image '${image}' is not in ${GHIDRA_IMAGES}`);
  return img.codeImage ?? img.id;
}

class Bridge {
  constructor(image, row, { headless, socketPath, ledger, logFile }) {
    this.image = image;
    this.row = row;
    this.socketPath = socketPath;
    this.ledger = ledger;
    this.logFile = logFile;
    this.tail = [];
    this.pending = new Map();
    this.nextId = 1;
    this.requests = 0;
    this.closed = null; // the reason, once the bridge is unusable
    this.stopping = false; // a requested shutdown: the socket closing and the run exiting are expected
    this.startedAt = new Date().toISOString();
    this.log = fs.createWriteStream(logFile, { flags: 'a' });
    const projectAbs = path.join(REPO_ROOT, row.projectDir);
    const args = [
      projectAbs, row.projectName, '-process', row.program, '-noanalysis',
      '-scriptPath', path.resolve(REPO_ROOT, GHIDRA_SCRIPTS),
      '-postScript', 'GhidraBridge.java', socketPath, image,
      path.resolve(REPO_ROOT, GHIDRA_ORDINALS), row.imports ? path.join(REPO_ROOT, row.imports) : '-', ledger,
    ];
    const javaOpts = row.settingsDir ? `-Dapplication.settingsdir=${path.join(REPO_ROOT, row.settingsDir)}` : '';
    // analyzeHeadless is a shell script that runs Java as its child: start it as the leader of its
    // own process group so ending the bridge ends the JVM (and its project lock) too.
    this.proc = spawn(headless, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      detached: true,
      env: { ...process.env, GHIDRA_HEADLESS_MAXMEM: GHIDRA_BRIDGE_MAXMEM, GHIDRA_HEADLESS_JAVA_OPTIONS: javaOpts },
    });
    // Resolves once the headless run has exited. A run that did not stop by request (killed, or
    // died) cannot remove its socket file, so the bridge removes it here.
    this.exited = new Promise((resolve) => {
      this.proc.once('exit', () => {
        if (!this.stopping) fs.rmSync(socketPath, { force: true });
        resolve();
      });
    });
    this.ready = new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.fail(`did not start listening within ${GHIDRA_BRIDGE_START_MS} ms`);
        reject(this.error());
      }, GHIDRA_BRIDGE_START_MS);
      const onLine = (line) => {
        this.record(line);
        if (line.includes('REPORT SCRIPT ERROR')) {
          clearTimeout(timer);
          this.fail('its GhidraBridge.java script stopped');
          reject(this.error());
        } else if (line.includes('GhidraBridge: listening on')) {
          clearTimeout(timer);
          this.connect().then(resolve, (e) => { this.fail(`listening, but the socket refused: ${e.message}`); reject(this.error()); });
        }
      };
      lines(this.proc.stdout, onLine);
      lines(this.proc.stderr, onLine);
      this.proc.on('exit', (code, signal) => {
        clearTimeout(timer);
        if (this.stopping) return;
        this.fail(`its headless run exited (code ${code}, signal ${signal})`);
        reject(this.error());
      });
      this.proc.on('error', (e) => {
        clearTimeout(timer);
        this.fail(`could not start ${headless}: ${e.message}`);
        reject(this.error());
      });
    });
    // A start failure is reported by bridgeFor; keep an unobserved rejection from crashing the server.
    this.ready.catch(() => {});
  }

  record(line) {
    this.log.write(`${line}\n`);
    this.tail.push(line);
    if (this.tail.length > LOG_TAIL) this.tail.shift();
  }

  error(msg = this.closed) {
    return new Error(`[ghidra-bridge] ${this.image}: ${msg}\n  log ${this.logFile}, last lines:\n${this.tail.map((l) => `    ${l}`).join('\n')}`);
  }

  // Mark the bridge unusable (once), fail every pending request and end the process.
  fail(reason) {
    if (this.closed) return;
    this.closed = reason;
    for (const [, p] of this.pending) {
      clearTimeout(p.timer);
      p.reject(this.error());
    }
    this.pending.clear();
    if (this.sock) this.sock.destroy();
    this.kill();
  }

  // SIGKILL the bridge's whole process group (the analyzeHeadless shell and its JVM), once.
  kill() {
    if (this.killed || this.proc.exitCode !== null || this.proc.signalCode !== null) return;
    this.killed = true;
    try {
      process.kill(-this.proc.pid, 'SIGKILL');
    } catch (e) {
      if (e.code !== 'ESRCH') throw e; // ESRCH: the group has already exited
    }
  }

  connect() {
    return new Promise((resolve, reject) => {
      const sock = net.createConnection(this.socketPath);
      sock.once('connect', () => {
        this.sock = sock;
        lines(sock, (line) => this.onResponse(line));
        sock.on('close', () => { if (!this.stopping) this.fail('its socket closed'); });
        resolve();
      });
      sock.once('error', reject);
    });
  }

  onResponse(line) {
    let msg;
    try { msg = JSON.parse(line); } catch (e) {
      this.fail(`sent a line that is not JSON (${e.message}): ${line.slice(0, 200)}`);
      return;
    }
    const p = this.pending.get(msg.id);
    if (!p) {
      this.fail(`answered request id ${JSON.stringify(msg.id)}, which is not pending`);
      return;
    }
    this.pending.delete(msg.id);
    clearTimeout(p.timer);
    if (msg.ok === true) p.resolve(msg.result);
    else p.reject(new Error(`[ghidra-bridge] ${this.image}: ${p.op}: ${msg.error}`));
  }

  async request(op, params = {}) {
    await this.ready;
    if (this.closed) throw this.error();
    const id = this.nextId++;
    this.requests++;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(this.error(`${op} took longer than ${GHIDRA_BRIDGE_REQUEST_MS} ms; the bridge was stopped`));
        this.fail(`${op} timed out`);
      }, GHIDRA_BRIDGE_REQUEST_MS);
      this.pending.set(id, { op, resolve, reject, timer });
      this.sock.write(`${JSON.stringify({ id, op, ...params })}\n`);
    });
  }

  /**
   * Ask the bridge to stop and wait for its headless run to end (it saves the program and removes
   * its socket). A run still alive `ms` after the shutdown answer is killed; that is an error.
   */
  async stop(ms = 120_000) {
    if (!this.closed) {
      const exited = this.exited.then(() => true);
      this.stopping = true;
      try {
        await this.request('shutdown');
      } catch (e) {
        this.stopping = false;
        this.fail(`shutdown failed: ${e.message}`);
        throw e;
      }
      let timer;
      const inTime = await Promise.race([exited, new Promise((resolve) => { timer = setTimeout(() => resolve(false), ms); })]);
      clearTimeout(timer);
      this.closed = 'stopped';
      if (!inTime) {
        this.kill();
        throw this.error(`its headless run did not exit within ${ms} ms of the shutdown answer; it was killed`);
      }
      if (fs.existsSync(this.socketPath)) {
        throw this.error(`its headless run exited but left its socket ${this.socketPath}`);
      }
    }
    this.log.end();
  }
}

/** Call `onLine` for every complete line `stream` emits. */
function lines(stream, onLine) {
  let buf = '';
  stream.setEncoding('utf8');
  stream.on('data', (chunk) => {
    buf += chunk;
    let i;
    while ((i = buf.indexOf('\n')) >= 0) {
      onLine(buf.slice(0, i).replace(/\r$/, ''));
      buf = buf.slice(i + 1);
    }
  });
}

const bridges = new Map(); // serving image id -> Bridge

/** The running bridge of `image` (its code image for a variant), started when there is none. */
export async function bridgeFor(image) {
  const images = readImagesTsv(path.resolve(REPO_ROOT, GHIDRA_IMAGES));
  const serving = servingImage(image, images);
  const existing = bridges.get(serving);
  if (existing && !existing.closed) {
    await existing.ready;
    return existing;
  }
  if (existing) {
    // A closed bridge has been killed; wait for its run to end (and its socket to be removed).
    await existing.exited;
    bridges.delete(serving);
  }
  const projects = readProjectsTsv(path.resolve(REPO_ROOT, GHIDRA_PROJECTS));
  const row = projects.get(serving);
  if (!row) throw new Error(`[ghidra-bridge] image ${serving} has no row in ${GHIDRA_PROJECTS}`);
  for (const [other, b] of bridges) {
    if (!b.closed && b.row.projectDir === row.projectDir && b.row.projectName === row.projectName) {
      throw new Error(`[ghidra-bridge] the Ghidra project ${row.projectDir}/${row.projectName} of ${serving} is held by the running ${other} bridge; stop it first (ghidra_bridge_stop ${other})`);
    }
  }
  if (!fs.existsSync(path.join(REPO_ROOT, row.projectDir, `${row.projectName}.gpr`))) {
    throw new Error(`[ghidra-bridge] ${serving}: no Ghidra project ${row.projectDir}/${row.projectName}.gpr`);
  }
  const headless = readGhidraHeadless(path.resolve(REPO_ROOT, GHIDRA_LOCAL_CONFIG));
  const socketPath = path.join(os.tmpdir(), `m2gb-${process.pid}-${serving}.sock`);
  if (Buffer.byteLength(socketPath) > MAX_SOCKET_PATH) {
    throw new Error(`[ghidra-bridge] socket path ${socketPath} is longer than ${MAX_SOCKET_PATH} bytes; set TMPDIR to a shorter directory`);
  }
  if (fs.existsSync(socketPath)) throw new Error(`[ghidra-bridge] socket ${socketPath} already exists (a bridge of this server process is still bound there)`);
  const outDir = path.join(REPO_ROOT, row.projectDir, '..', 'out');
  fs.mkdirSync(outDir, { recursive: true });
  const bridge = new Bridge(serving, row, {
    headless,
    socketPath,
    ledger: path.join(outDir, 'bridge_edits.tsv'),
    logFile: path.join(outDir, `bridge_${serving}.log`),
  });
  bridges.set(serving, bridge);
  await bridge.ready;
  return bridge;
}

/** One request to the bridge serving `image`; `va` (any address spelling) is normalized to 0x%08x. */
export async function ghidraRequest(image, op, params = {}) {
  const b = await bridgeFor(image);
  return { image, served_by: b.image, result: await b.request(op, params) };
}

/** Stop the bridge serving `image` (its headless run saves and exits). */
export async function stopBridge(image) {
  const images = readImagesTsv(path.resolve(REPO_ROOT, GHIDRA_IMAGES));
  const serving = servingImage(image, images);
  const b = bridges.get(serving);
  if (!b) throw new Error(`[ghidra-bridge] no bridge is running for ${serving}`);
  bridges.delete(serving);
  await b.stop();
  return { stopped: serving, requests: b.requests, ledger: b.ledger, log: b.logFile };
}

/** The bridges this process started. */
export function listBridges() {
  return [...bridges.values()].map((b) => ({
    image: b.image,
    project: `${b.row.projectDir}/${b.row.projectName}`,
    program: b.row.program,
    pid: b.proc.pid,
    started: b.startedAt,
    requests: b.requests,
    state: b.closed ? `closed: ${b.closed}` : 'running',
    ledger: b.ledger,
    log: b.logFile,
  }));
}

/** Stop every bridge (each saves and exits); one that does not exit within `ms` is killed and reported. */
export async function stopAllBridges(ms = 60_000) {
  const all = [...bridges.values()];
  bridges.clear();
  await Promise.all(all.map((b) => b.stop(ms)));
}

/** Kill every bridge now (synchronous, for process exit): edits are already saved, so nothing is lost. */
export function killAllBridges() {
  for (const b of bridges.values()) {
    b.kill();
    fs.rmSync(b.socketPath, { force: true });
  }
  bridges.clear();
}
