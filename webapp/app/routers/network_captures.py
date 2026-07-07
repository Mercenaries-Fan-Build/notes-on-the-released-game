from __future__ import annotations

import asyncio
import json

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import StreamingResponse
from sqlalchemy import Text, delete, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import PaginationParams
from app.events import broker
from app.models import NetworkCapture
from app.schemas.common import PaginatedResponse
from app.schemas.network_capture import NetworkCaptureCreate, NetworkCaptureRead

router = APIRouter(prefix="/network-captures", tags=["network-captures"])


@router.post("", response_model=NetworkCaptureRead, status_code=201)
async def create_capture(
    payload: NetworkCaptureCreate,
    db: AsyncSession = Depends(get_db),
):
    """Ingest one captured event from the capture sink (coopserver / tlsterm)."""
    row = NetworkCapture(**payload.model_dump())
    db.add(row)
    await db.commit()
    await db.refresh(row)
    # Fan out to any live inspector clients (best-effort; DB is the record).
    broker.publish(NetworkCaptureRead.model_validate(row).model_dump(mode="json"))
    return row


@router.get("/stream")
async def stream_captures(request: Request):
    """Server-Sent-Events feed of captures as they are ingested — the live
    'watch the game talk' wire for the inspector. Each event is one capture as
    JSON. A periodic ``:keepalive`` comment stops idle proxies/browsers from
    dropping the connection."""
    queue = broker.subscribe()

    async def gen():
        try:
            # Prime the stream so the client knows it's connected.
            yield ": connected\n\n"
            while True:
                if await request.is_disconnected():
                    break
                try:
                    event = await asyncio.wait_for(queue.get(), timeout=15.0)
                except asyncio.TimeoutError:
                    yield ": keepalive\n\n"
                    continue
                yield f"data: {json.dumps(event)}\n\n"
        finally:
            broker.unsubscribe(queue)

    return StreamingResponse(gen(), media_type="text/event-stream", headers={
        "Cache-Control": "no-cache",
        "X-Accel-Buffering": "no",
    })


@router.get("", response_model=PaginatedResponse[NetworkCaptureRead])
async def list_captures(
    pag: PaginationParams = Depends(),
    protocol: str | None = Query(default=None),
    host: str | None = Query(default=None),
    fesl_txn: str | None = Query(default=None),
    search: str | None = Query(default=None, description="Search path / params / body"),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(NetworkCapture)
    # Newest first — this is a live event log.
    q = select(NetworkCapture).order_by(NetworkCapture.id.desc())

    def apply(stmt):
        if protocol:
            stmt = stmt.where(NetworkCapture.protocol == protocol)
        if host:
            stmt = stmt.where(NetworkCapture.host.ilike(f"%{host}%"))
        if fesl_txn:
            stmt = stmt.where(NetworkCapture.fesl_txn == fesl_txn)
        if search:
            pat = f"%{search}%"
            stmt = stmt.where(
                or_(
                    NetworkCapture.path.ilike(pat),
                    NetworkCapture.body_text.ilike(pat),
                    NetworkCapture.fesl_txn.ilike(pat),
                    NetworkCapture.params.cast(Text).ilike(pat),
                )
            )
        return stmt

    count_q = apply(count_q)
    q = apply(q)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@router.get("/{capture_id}", response_model=NetworkCaptureRead)
async def get_capture(capture_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(NetworkCapture, capture_id)
    if not row:
        raise HTTPException(404, "Capture not found")
    return row


@router.delete("", status_code=204)
async def clear_captures(db: AsyncSession = Depends(get_db)):
    """Clear the capture log (useful between test runs)."""
    await db.execute(delete(NetworkCapture))
    await db.commit()
