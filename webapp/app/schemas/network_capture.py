from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class NetworkCaptureBase(BaseModel):
    protocol: str
    direction: str | None = None
    peer_addr: str | None = None
    server_port: int | None = None
    host: str | None = None
    method: str | None = None
    path: str | None = None
    fesl_type: str | None = None
    fesl_txn: str | None = None
    fesl_id: int | None = None
    headers: dict[str, Any] | None = None
    params: dict[str, Any] | None = None
    body_text: str | None = None
    body_hex: str | None = None
    body_len: int | None = None
    response_summary: str | None = None
    notes: str | None = None


class NetworkCaptureCreate(NetworkCaptureBase):
    """Payload posted by the coopserver capture sink."""

    pass


class NetworkCaptureRead(NetworkCaptureBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime | None = None
