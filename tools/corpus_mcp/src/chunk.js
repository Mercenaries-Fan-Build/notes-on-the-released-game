import crypto from 'node:crypto';
import { CHUNK_TARGET, CHUNK_OVERLAP } from './config.js';

export function sha256(text) {
  return crypto.createHash('sha256').update(text).digest('hex');
}

/** Normalize a hex address token to 8 lowercase hex digits ("00478120"). */
export function normAddr(hex) {
  const h = hex.toLowerCase().replace(/^0+/, '') || '0';
  return h.padStart(8, '0');
}

const ADDR_RE = /(?:FUN_|DAT_|LAB_|SUB_|0x)([0-9a-fA-F]{5,8})\b/g;

/** Extract every engine address mentioned in a text, normalized + deduped,
 *  returned as a space-delimited string (stored in the `addrs` column so
 *  exact cross-references work via LIKE regardless of FUN_/0x spelling). */
export function extractAddrs(text) {
  const seen = new Set();
  for (const m of text.matchAll(ADDR_RE)) seen.add(normAddr(m[1]));
  return [...seen].join(' ');
}

/** Split text into ~target-char chunks on paragraph/line boundaries with overlap. */
export function chunkText(text, target = CHUNK_TARGET, overlap = CHUNK_OVERLAP) {
  const clean = text.replace(/\r\n/g, '\n');
  if (clean.length <= target * 1.3) return clean.trim() ? [clean.trim()] : [];
  const parts = clean.split(/\n{2,}/);
  const chunks = [];
  let cur = '';
  for (let part of parts) {
    // A single oversized paragraph (e.g. a big code block) gets hard-split on lines.
    while (part.length > target * 1.5) {
      const cut = part.lastIndexOf('\n', target) > target / 2 ? part.lastIndexOf('\n', target) : target;
      const head = part.slice(0, cut);
      if (cur) { chunks.push(cur); cur = cur.slice(-overlap); }
      chunks.push((cur + '\n\n' + head).trim());
      cur = head.slice(-overlap);
      part = part.slice(cut);
    }
    if (cur.length + part.length + 2 > target && cur.trim()) {
      chunks.push(cur.trim());
      cur = cur.slice(-overlap);
    }
    cur = cur ? cur + '\n\n' + part : part;
  }
  if (cur.trim()) chunks.push(cur.trim());
  return chunks.filter((c) => c.length > 20);
}

/** Markdown-aware: keep the nearest heading path as a prefix on each chunk. */
export function chunkMarkdown(text) {
  const lines = text.replace(/\r\n/g, '\n').split('\n');
  const sections = [];
  let heading = '';
  let buf = [];
  for (const line of lines) {
    const m = line.match(/^(#{1,4})\s+(.*)/);
    if (m) {
      if (buf.join('\n').trim()) sections.push({ heading, body: buf.join('\n') });
      heading = m[2].trim();
      buf = [line];
    } else {
      buf.push(line);
    }
  }
  if (buf.join('\n').trim()) sections.push({ heading, body: buf.join('\n') });
  const chunks = [];
  for (const s of sections) {
    for (const c of chunkText(s.body)) {
      chunks.push(s.heading && !c.includes(s.heading) ? `[${s.heading}]\n${c}` : c);
    }
  }
  return chunks;
}

/** Code: chunk on line windows so functions stay mostly intact. */
export function chunkCode(text, linesPer = 90, overlapLines = 12) {
  const lines = text.replace(/\r\n/g, '\n').split('\n');
  if (lines.length <= linesPer * 1.3) {
    const t = text.trim();
    return t ? [t] : [];
  }
  const chunks = [];
  for (let i = 0; i < lines.length; i += linesPer - overlapLines) {
    const c = lines.slice(i, i + linesPer).join('\n').trim();
    if (c.length > 20) chunks.push(c);
    if (i + linesPer >= lines.length) break;
  }
  return chunks;
}
