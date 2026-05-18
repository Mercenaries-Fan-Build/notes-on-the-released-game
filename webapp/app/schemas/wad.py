from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class WadArchiveBase(BaseModel):
    name: str
    filename: str | None = None
    file_path: str | None = None
    file_size_bytes: int | None = None
    ffcs_version: int | None = None
    block_count: int | None = None
    indx_offset: int | None = None
    indx_entry_count: int | None = None
    data_offset: int | None = None
    data_segment_count: int | None = None
    data_size_bytes: int | None = None
    csum_entry_count: int | None = None
    aset_offset: int | None = None
    aset_entry_count: int | None = None
    aset_size_bytes: int | None = None
    pths_offset: int | None = None
    pths_entry_count: int | None = None
    pths_size_bytes: int | None = None
    chunk_summary: Any | None = None


class WadArchiveCreate(WadArchiveBase):
    pass


class WadArchiveRead(WadArchiveBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime | None = None
