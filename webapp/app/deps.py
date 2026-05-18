from __future__ import annotations

from dataclasses import dataclass

from fastapi import Query

from app.config import settings


@dataclass
class PaginationParams:
    offset: int = Query(default=0, ge=0, description="Number of records to skip")
    limit: int = Query(
        default=settings.page_size_default,
        ge=1,
        le=settings.page_size_max,
        description="Max records to return",
    )


@dataclass
class BlockFilterParams:
    search: str | None = Query(default=None, description="Full-text search on name/stem")
    block_type: str | None = Query(default=None, description="Filter by block_type")
    category_id: int | None = Query(default=None, description="Filter by category id")
    has_geometry: bool | None = Query(default=None, description="Filter blocks with geometry")
    has_textures: bool | None = Query(default=None, description="Filter blocks with textures")
    has_animations: bool | None = Query(default=None, description="Filter blocks with animations")
    review_status: str | None = Query(default=None, description="Filter by review status")
    faction_hint: str | None = Query(default=None, description="Filter by faction hint")
    region_hint: str | None = Query(default=None, description="Filter by region hint")


@dataclass
class PlacementFilterParams:
    search: str | None = Query(default=None, description="Search entity_name")
    block_type: str | None = Query(default=None, description="Filter by block_type")
    category_id: int | None = Query(default=None, description="Filter by category id")
    vz_state_overlay_id: int | None = Query(default=None, description="Filter by vz_state overlay")
    linked_block_id: int | None = Query(default=None, description="Filter by linked block")
    visibility_default: bool | None = Query(default=None, description="Filter by default visibility")
