from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class WorldCellBase(BaseModel):
    cell_id: int
    block_id: int | None = None
    row: int | None = None
    col: int | None = None
    center_x: float | None = None
    center_y: float | None = None
    center_z: float | None = None
    vertex_count: int | None = None
    has_glb: bool | None = None
    has_gltf: bool | None = None
    cell_size_x: float | None = None
    cell_size_z: float | None = None
    placement_count: int | None = None


class WorldCellCreate(WorldCellBase):
    pass


class WorldCellRead(WorldCellBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class TerrainTileBase(BaseModel):
    toc_index: int | None = None
    iter_index: int | None = None
    mesh_hash: str | None = None
    mesh_hash_int: int | None = None
    row: int | None = None
    col: int | None = None
    center_x: float | None = None
    center_z: float | None = None
    vertex_count: int | None = None
    is_ocean_tile: bool | None = None
    bbox_center_x: float | None = None
    bbox_center_y: float | None = None
    bbox_center_z: float | None = None
    bbox_radius: float | None = None


class TerrainTileCreate(TerrainTileBase):
    pass


class TerrainTileRead(TerrainTileBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class ZoneBase(BaseModel):
    name: str
    zone_type: str | None = None
    faction_id: int | None = None
    act: str | None = None
    description: str | None = None
    color_hex: str | None = None
    opacity: float | None = None
    min_elevation: float | None = None
    max_elevation: float | None = None
    is_active: bool = True
    sort_order: int = 0
    properties: Any | None = None


class ZoneCreate(ZoneBase):
    pass


class ZoneUpdate(BaseModel):
    name: str | None = None
    zone_type: str | None = None
    faction_id: int | None = None
    description: str | None = None
    color_hex: str | None = None
    opacity: float | None = None
    is_active: bool | None = None
    properties: Any | None = None


class ZoneRead(ZoneBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime | None = None
    updated_at: datetime | None = None


class SplineBase(BaseModel):
    name: str | None = None
    spline_type: str | None = None
    zone_id: int | None = None
    faction_id: int | None = None
    is_loop: bool | None = None
    description: str | None = None
    color_hex: str | None = None
    properties: Any | None = None


class SplineCreate(SplineBase):
    pass


class SplineRead(SplineBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime | None = None
    updated_at: datetime | None = None


class SpawnerBase(BaseModel):
    name: str | None = None
    spawner_type: str | None = None
    zone_id: int | None = None
    faction_id: int | None = None
    pos_x: float | None = None
    pos_y: float | None = None
    pos_z: float | None = None
    radius: float | None = None
    spawn_count: int | None = None
    respawn_time: float | None = None
    patrol_spline_id: int | None = None
    properties: Any | None = None


class SpawnerCreate(SpawnerBase):
    pass


class SpawnerRead(SpawnerBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime | None = None
