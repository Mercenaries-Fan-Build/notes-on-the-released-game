from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict


class TextureBase(BaseModel):
    name: str
    asset_hash: str | None = None
    asset_hash_int: int | None = None
    width: int | None = None
    height: int | None = None
    mip_count: int | None = None
    fourcc: str | None = None
    total_size_bytes: int | None = None
    is_global: bool | None = None
    texture_channel: str | None = None
    base_texture_name: str | None = None
    source_block_count: int | None = None
    first_seen_block_id: int | None = None


class TextureCreate(TextureBase):
    pass


class TextureRead(TextureBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class TextureIndexEntryBase(BaseModel):
    asset_hash: str | None = None
    asset_hash_int: int | None = None
    texture_name: str | None = None
    source_block_path: str | None = None
    body_offset: int | None = None
    body_size: int | None = None
    block_id: int | None = None


class TextureIndexEntryCreate(TextureIndexEntryBase):
    pass


class TextureIndexEntryRead(TextureIndexEntryBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
