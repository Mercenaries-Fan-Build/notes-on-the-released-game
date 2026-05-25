from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class BlockBase(BaseModel):
    wad_id: int | None = None
    block_index: int | None = None
    path: str | None = None
    stem: str
    canonical_name: str | None = None
    base_asset_id: str | None = None
    p_level: int | None = None
    q_level: int | None = None
    pack: str | None = None
    block_type: str | None = None
    category_id: int | None = None
    review_status: str = "unreviewed"
    review_notes: str | None = None
    reviewed_by: str | None = None
    reviewed_at: datetime | None = None
    file_size_bytes: int | None = None
    compressed_size_bytes: int | None = None
    has_geometry: bool = False
    has_textures: bool = False
    has_havok: bool = False
    has_animations: bool = False
    has_lua: bool = False
    has_audio: bool = False
    has_dialog: bool = False
    thumbnail_path: str | None = None
    review_dir_path: str | None = None
    glb_path: str | None = None
    gltf_path: str | None = None
    obj_path: str | None = None
    variant_type: str | None = None
    variant_tags: Any | None = None
    texture_channel_hint: str | None = None
    faction_hint: str | None = None
    region_hint: str | None = None
    ucfx_offset_count: int | None = None
    primary_ucfx_offset: int | None = None
    ucfx_offsets: Any | None = None
    tag_occurrences: Any | None = None
    strings_sample: Any | None = None
    geom_chunk_trees: Any | None = None
    raw_ucfx_json: Any | None = None


class BlockCreate(BlockBase):
    pass


class BlockUpdate(BaseModel):
    category_id: int | None = None
    review_status: str | None = None
    review_notes: str | None = None
    reviewed_by: str | None = None
    linked_block_id: int | None = None
    variant_type: str | None = None
    variant_tags: Any | None = None


class BlockRead(BlockBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime | None = None
    updated_at: datetime | None = None


class BlockMeshMetaBase(BaseModel):
    block_id: int
    total_vertices: int | None = None
    total_faces: int | None = None
    topology: str | None = None
    extraction_method: str | None = None
    mesh_group_count: int | None = None
    transparent_count: int | None = None
    lod_mode: str | None = None
    material_indices: Any | None = None
    notes: str | None = None
    bbox_volume: float | None = None
    bbox_min_x: float | None = None
    bbox_min_y: float | None = None
    bbox_min_z: float | None = None
    bbox_max_x: float | None = None
    bbox_max_y: float | None = None
    bbox_max_z: float | None = None
    bbox_center_x: float | None = None
    bbox_center_y: float | None = None
    bbox_center_z: float | None = None
    extent_x: float | None = None
    extent_y: float | None = None
    extent_z: float | None = None
    max_extent: float | None = None
    is_flat: bool | None = None
    raw_meta_json: Any | None = None


class BlockMeshMetaCreate(BlockMeshMetaBase):
    pass


class BlockMeshMetaRead(BlockMeshMetaBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class SubmeshBase(BaseModel):
    block_id: int
    submesh_index: int
    obj_filename: str | None = None
    vertex_count: int | None = None
    face_count: int | None = None
    stride_bytes: int | None = None
    vertex_format: str | None = None
    material_index: int | None = None
    is_transparent: bool | None = None
    transparency_flag: float | None = None
    lod_group: int | None = None
    lod_rank: int | None = None
    is_vehicle_lod: bool | None = None
    lod_alternatives: Any | None = None
    mesh_group_id: int | None = None
    mesh_draw_index: int | None = None
    prmt_draw_index: int | None = None
    texture_diffuse: str | None = None
    texture_normal: str | None = None
    texture_specular: str | None = None
    hier_node_idx: int | None = None
    damage_state: str | None = None
    instanced_from: int | None = None
    bbox_min_x: float | None = None
    bbox_min_y: float | None = None
    bbox_min_z: float | None = None
    bbox_max_x: float | None = None
    bbox_max_y: float | None = None
    bbox_max_z: float | None = None
    bbox_volume: float | None = None
    prmg_bbox_min_x: float | None = None
    prmg_bbox_min_y: float | None = None
    prmg_bbox_min_z: float | None = None
    prmg_bbox_max_x: float | None = None
    prmg_bbox_max_y: float | None = None
    prmg_bbox_max_z: float | None = None
    world_translation_x: float | None = None
    world_translation_y: float | None = None
    world_translation_z: float | None = None
    world_rotation_3x3: Any | None = None
    hier_instance_nodes: Any | None = None
    vb_file_offset: int | None = None
    vb_len: int | None = None
    ib_file_offset: int | None = None
    ib_len: int | None = None
    n_indices: int | None = None
    index_max: int | None = None


class SubmeshCreate(SubmeshBase):
    pass


class SubmeshRead(SubmeshBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
