"""In-process pub/sub for live capture streaming (the inspector's SSE feed).

Every ingested capture is published to all connected Server-Sent-Events clients
so the Wireshark-like inspector updates in real time as the game talks. This is
deliberately in-memory / single-process — the capture volume is a handful of
events per second and the inspector is a local dev tool, so a broker service
would be overkill. The database remains the durable record; this is just the
live fan-out.
"""
from __future__ import annotations

import asyncio
from typing import Any


class CaptureBroker:
    def __init__(self) -> None:
        self._subscribers: set[asyncio.Queue] = set()

    def subscribe(self) -> asyncio.Queue:
        q: asyncio.Queue = asyncio.Queue(maxsize=1000)
        self._subscribers.add(q)
        return q

    def unsubscribe(self, q: asyncio.Queue) -> None:
        self._subscribers.discard(q)

    def publish(self, event: dict[str, Any]) -> None:
        """Fan one capture out to every live subscriber. Non-blocking: a slow
        client that has filled its queue drops the event rather than stalling
        ingest (the DB still has it; the client can refetch)."""
        for q in list(self._subscribers):
            try:
                q.put_nowait(event)
            except asyncio.QueueFull:
                pass

    @property
    def subscriber_count(self) -> int:
        return len(self._subscribers)


broker = CaptureBroker()
