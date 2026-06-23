"""Capture sink — fan every captured event out to (a) a JSONL file and (b) the
Modkit webapp ingest API.

The JSONL file is the source of truth (httpbin-style raw dump, grep-able, works
even if the database is down). The API POST is best-effort and buffered through
a queue + worker so a slow/unavailable webapp never blocks the game's traffic.
"""
from __future__ import annotations

import asyncio
import datetime as _dt
import json
import os
import sys

import httpx

from config import config

# Fields accepted by webapp NetworkCaptureCreate. We pass exactly these through.
_DB_FIELDS = (
    "protocol", "direction", "peer_addr", "server_port", "host",
    "method", "path", "fesl_type", "fesl_txn", "fesl_id",
    "headers", "params", "body_text", "body_hex", "body_len",
    "response_summary", "notes",
)


def _now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat()


def _strip_nuls(value):
    """Recursively drop NUL (\\x00) bytes from strings — Postgres TEXT/JSON
    columns reject them, and FESL payloads are NUL-terminated/­padded."""
    if isinstance(value, str):
        return value.replace("\x00", "") if "\x00" in value else value
    if isinstance(value, dict):
        return {_strip_nuls(k): _strip_nuls(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_strip_nuls(v) for v in value]
    return value


def log(msg: str) -> None:
    print(f"[coopserver {_now()}] {msg}", file=sys.stderr, flush=True)


class CaptureSink:
    def __init__(self) -> None:
        self._queue: asyncio.Queue[dict] = asyncio.Queue(maxsize=10000)
        self._file_lock = asyncio.Lock()
        self._client: httpx.AsyncClient | None = None
        self._jsonl_path = ""

    async def start(self) -> None:
        os.makedirs(config.capture_dir, exist_ok=True)
        day = _dt.datetime.now(_dt.timezone.utc).strftime("%Y%m%d")
        self._jsonl_path = os.path.join(config.capture_dir, f"capture-{day}.jsonl")
        if config.api_url:
            self._client = httpx.AsyncClient(timeout=5.0)
        asyncio.create_task(self._api_worker())
        log(f"sink ready — jsonl={self._jsonl_path} api={config.api_url or '(disabled)'}")

    async def emit(self, record: dict) -> None:
        """Record one event. ``record`` keys should match NetworkCapture fields."""
        record = _strip_nuls(record)
        record.setdefault("ts", _now())
        # Console line — gives the live "watching the game talk" feel in logs.
        log(
            f"{record.get('protocol','?').upper():7} "
            f"{record.get('peer_addr','?'):>21} -> :{record.get('server_port','?')} "
            f"{record.get('host') or ''} "
            f"{record.get('method') or record.get('fesl_type') or ''} "
            f"{record.get('path') or record.get('fesl_txn') or ''} "
            f"({record.get('body_len', 0)}B)"
        )
        await self._write_jsonl(record)
        try:
            self._queue.put_nowait(record)
        except asyncio.QueueFull:
            log("WARN api queue full — dropping DB ingest for this event (JSONL kept)")

    async def _write_jsonl(self, record: dict) -> None:
        line = json.dumps(record, ensure_ascii=False, default=str)
        async with self._file_lock:
            await asyncio.to_thread(self._append, line)

    def _append(self, line: str) -> None:
        with open(self._jsonl_path, "a", encoding="utf-8") as fh:
            fh.write(line + "\n")

    async def _api_worker(self) -> None:
        if not self._client:
            # Drain quietly so producers never block.
            while True:
                await self._queue.get()
                self._queue.task_done()
        url = config.api_url.rstrip("/") + "/api/network-captures"
        while True:
            record = await self._queue.get()
            payload = {k: record.get(k) for k in _DB_FIELDS}
            try:
                resp = await self._client.post(url, json=payload)
                if resp.status_code >= 300:
                    log(f"WARN api ingest HTTP {resp.status_code}: {resp.text[:200]}; "
                        f"event preserved in JSONL")
            except Exception as exc:  # noqa: BLE001 — best effort, JSONL is canonical
                log(f"WARN api ingest failed ({exc}); event preserved in JSONL")
            finally:
                self._queue.task_done()


sink = CaptureSink()
