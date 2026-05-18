from __future__ import annotations

from datetime import datetime
from typing import Any, Generic, TypeVar

from pydantic import BaseModel, ConfigDict

T = TypeVar("T")


class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    total: int
    offset: int
    limit: int


class StatsResponse(BaseModel):
    blocks: int = 0
    placements: int = 0
    textures: int = 0
    categories: int = 0
    ecs_records: int = 0
    animation_groups: int = 0
    world_cells: int = 0
    wad_archives: int = 0
    vz_state_overlays: int = 0
    missions: int = 0
    factions: int = 0
    lua_chunks: int = 0
    dialog_fragments: int = 0
    aset_rows: int = 0


class HealthResponse(BaseModel):
    status: str = "ok"
    database: str = "connected"
