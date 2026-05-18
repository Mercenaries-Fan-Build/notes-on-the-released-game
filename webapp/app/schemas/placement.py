from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict


class PlacementBase(BaseModel):
    entity_id: str | None = None
    entity_key: int | None = None
    entity_name: str | None = None
    block_type: str | None = None
    source_block: str | None = None
    sub_block: int | None = None
    pos_x: float | None = None
    pos_y: float | None = None
    pos_z: float | None = None
    quat_x: float | None = None
    quat_y: float | None = None
    quat_z: float | None = None
    quat_w: float | None = None
    rotation_y_deg: float | None = None
    rotation_y_rad: float | None = None
    has_non_trivial_rotation: bool | None = None
    ue_pos_x: float | None = None
    ue_pos_y: float | None = None
    ue_pos_z: float | None = None
    ue_yaw: float | None = None
    ue_pitch: float | None = None
    ue_roll: float | None = None
    model_name_hash: str | None = None
    linked_block_id: int | None = None
    vz_state_source: str | None = None
    vz_state_overlay_id: int | None = None
    type_hash: str | None = None
    boot_float: float | None = None
    boot_u32: str | None = None
    rotation_y_sin: float | None = None
    visibility_default: bool | None = None
    category_id: int | None = None
    cell_id: int | None = None
    cell_row: int | None = None
    cell_col: int | None = None
    distance_from_origin: float | None = None
    elevation_band: str | None = None


class PlacementCreate(PlacementBase):
    pass


class PlacementRead(PlacementBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class PlacementUpdate(BaseModel):
    linked_block_id: int | None = None
    category_id: int | None = None
    visibility_default: bool | None = None


class VzStateOverlayBase(BaseModel):
    source_name: str
    source_block_stem: str | None = None
    block_id: int | None = None
    faction: str | None = None
    stage: str | None = None
    parent_kind: str | None = None
    act: str | None = None
    is_act_overlay: bool | None = None
    region: str | None = None
    mission_id: str | None = None
    placement_count: int | None = None
    visibility_default: bool | None = None
    description: str | None = None


class VzStateOverlayCreate(VzStateOverlayBase):
    pass


class VzStateOverlayRead(VzStateOverlayBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
