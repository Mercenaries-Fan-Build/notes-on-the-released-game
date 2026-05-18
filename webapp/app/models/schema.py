from __future__ import annotations

from typing import Optional

from geoalchemy2 import Geometry
from sqlalchemy import (
    BigInteger,
    Boolean,
    Float,
    ForeignKey,
    Index,
    Integer,
    JSON,
    SmallInteger,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import DateTime

from app.models.base import Base


# ---------------------------------------------------------------------------
# WAD / Archive layer
# ---------------------------------------------------------------------------

class WadArchive(Base):
    __tablename__ = "wad_archives"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    filename: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    file_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    file_size_bytes: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    ffcs_version: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    block_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    indx_offset: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    indx_entry_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    data_offset: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    data_segment_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    data_size_bytes: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    csum_entry_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    aset_offset: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    aset_entry_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    aset_size_bytes: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    pths_offset: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    pths_entry_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    pths_size_bytes: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    chunk_summary: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    created_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    blocks: Mapped[list[Block]] = relationship(back_populates="wad")
    aset_rows: Mapped[list[AsetRow]] = relationship(back_populates="wad")


# ---------------------------------------------------------------------------
# Category / Tag taxonomy
# ---------------------------------------------------------------------------

class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    slug: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    parent_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("categories.id"), nullable=True
    )
    depth: Mapped[int] = mapped_column(SmallInteger, default=0)
    path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    color_hex: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    icon: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    auto_pattern: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    parent: Mapped[Optional[Category]] = relationship(
        remote_side="Category.id", back_populates="children"
    )
    children: Mapped[list[Category]] = relationship(back_populates="parent")
    blocks: Mapped[list[Block]] = relationship(back_populates="category")


class Tag(Base):
    __tablename__ = "tags"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    slug: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    color_hex: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class BlockTag(Base):
    __tablename__ = "block_tags"

    block_id: Mapped[int] = mapped_column(
        ForeignKey("blocks.id"), primary_key=True
    )
    tag_id: Mapped[int] = mapped_column(
        ForeignKey("tags.id"), primary_key=True
    )
    created_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


# ---------------------------------------------------------------------------
# Blocks – the core asset unit
# ---------------------------------------------------------------------------

class Block(Base):
    __tablename__ = "blocks"
    __table_args__ = (
        Index("ix_blocks_block_type", "block_type"),
        Index("ix_blocks_category_id", "category_id"),
        Index("ix_blocks_review_status", "review_status"),
        Index("ix_blocks_canonical_name", "canonical_name"),
        Index("ix_blocks_base_asset_id", "base_asset_id"),
        Index("ix_blocks_faction_hint", "faction_hint"),
        Index("ix_blocks_region_hint", "region_hint"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    wad_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("wad_archives.id"), nullable=True
    )
    block_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    stem: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    canonical_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    base_asset_id: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    p_level: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    q_level: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    pack: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    block_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    category_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("categories.id"), nullable=True
    )
    review_status: Mapped[str] = mapped_column(
        Text, nullable=False, default="unreviewed"
    )
    review_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reviewed_by: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    reviewed_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    file_size_bytes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    compressed_size_bytes: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True
    )
    has_geometry: Mapped[bool] = mapped_column(Boolean, default=False)
    has_textures: Mapped[bool] = mapped_column(Boolean, default=False)
    has_havok: Mapped[bool] = mapped_column(Boolean, default=False)
    has_animations: Mapped[bool] = mapped_column(Boolean, default=False)
    has_lua: Mapped[bool] = mapped_column(Boolean, default=False)
    has_audio: Mapped[bool] = mapped_column(Boolean, default=False)
    has_dialog: Mapped[bool] = mapped_column(Boolean, default=False)
    thumbnail_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    review_dir_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    glb_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    gltf_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    obj_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    variant_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    variant_tags: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    texture_channel_hint: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    faction_hint: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    region_hint: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    ucfx_offset_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    primary_ucfx_offset: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    ucfx_offsets: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    tag_occurrences: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    strings_sample: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    geom_chunk_trees: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    raw_ucfx_json: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    created_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), onupdate=func.now(), nullable=True
    )

    wad: Mapped[Optional[WadArchive]] = relationship(back_populates="blocks")
    category: Mapped[Optional[Category]] = relationship(back_populates="blocks")
    mesh_meta: Mapped[Optional[BlockMeshMeta]] = relationship(back_populates="block")
    submeshes: Mapped[list[Submesh]] = relationship(back_populates="block")
    havok_slices: Mapped[list[HavokSlice]] = relationship(back_populates="block")
    dialog_fragments: Mapped[list[DialogFragment]] = relationship(
        back_populates="block"
    )
    lua_chunks: Mapped[list[LuaChunk]] = relationship(back_populates="block")
    animation_groups: Mapped[list[AnimationGroup]] = relationship(
        back_populates="block"
    )


# ---------------------------------------------------------------------------
# Mesh / geometry metadata
# ---------------------------------------------------------------------------

class BlockMeshMeta(Base):
    __tablename__ = "block_mesh_meta"

    id: Mapped[int] = mapped_column(primary_key=True)
    block_id: Mapped[int] = mapped_column(
        ForeignKey("blocks.id"), unique=True, nullable=False
    )
    total_vertices: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    total_faces: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    topology: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    extraction_method: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    mesh_group_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    transparent_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    lod_mode: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    material_indices: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    bbox_volume: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_min_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_min_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_min_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_max_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_max_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_max_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_center_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_center_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_center_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    extent_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    extent_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    extent_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    max_extent: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    is_flat: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    has_nan_normals: Mapped[Optional[bool]] = mapped_column(
        Boolean, server_default="false", nullable=True
    )
    has_nan_uvs: Mapped[Optional[bool]] = mapped_column(
        Boolean, server_default="false", nullable=True
    )
    mesh_meta_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    mesh_meta_size_bytes: Mapped[Optional[int]] = mapped_column(
        BigInteger, nullable=True
    )
    raw_meta_json: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)

    block: Mapped[Block] = relationship(back_populates="mesh_meta")


class Submesh(Base):
    __tablename__ = "submeshes"

    id: Mapped[int] = mapped_column(primary_key=True)
    block_id: Mapped[int] = mapped_column(
        ForeignKey("blocks.id"), nullable=False
    )
    submesh_index: Mapped[int] = mapped_column(Integer, nullable=False)
    obj_filename: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    vertex_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    face_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    stride_bytes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    vertex_format: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    material_index: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    is_transparent: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    transparency_flag: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    lod_group: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    lod_rank: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    is_vehicle_lod: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    lod_alternatives: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    mesh_group_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    mesh_draw_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    prmt_draw_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    texture_diffuse: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    texture_normal: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    texture_specular: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    hier_node_idx: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    damage_state: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    instanced_from: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    bbox_min_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_min_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_min_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_max_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_max_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_max_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_volume: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    prmg_bbox_min_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    prmg_bbox_min_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    prmg_bbox_min_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    prmg_bbox_max_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    prmg_bbox_max_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    prmg_bbox_max_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    world_translation_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    world_translation_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    world_translation_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    world_rotation_3x3: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    hier_instance_nodes: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    vb_file_offset: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    vb_len: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    ib_file_offset: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    ib_len: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    n_indices: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    index_max: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    nan_uv_count: Mapped[Optional[int]] = mapped_column(
        Integer, server_default="0", nullable=True
    )
    nan_normal_count: Mapped[Optional[int]] = mapped_column(
        Integer, server_default="0", nullable=True
    )

    block: Mapped[Block] = relationship(back_populates="submeshes")


# ---------------------------------------------------------------------------
# Textures
# ---------------------------------------------------------------------------

class Texture(Base):
    __tablename__ = "textures"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    asset_hash: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    asset_hash_int: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    width: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    height: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    mip_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    fourcc: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    total_size_bytes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    is_global: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    texture_channel: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    base_texture_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    source_block_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    first_seen_block_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("blocks.id"), nullable=True
    )


class BlockTexture(Base):
    __tablename__ = "block_textures"

    id: Mapped[int] = mapped_column(primary_key=True)
    block_id: Mapped[int] = mapped_column(
        ForeignKey("blocks.id"), nullable=False
    )
    texture_id: Mapped[int] = mapped_column(
        ForeignKey("textures.id"), nullable=False
    )
    is_shared: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    is_local: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    body_offset: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    body_size: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)


# ---------------------------------------------------------------------------
# World placements & vz_state overlays
# ---------------------------------------------------------------------------

class VzStateOverlay(Base):
    __tablename__ = "vz_state_overlays"

    id: Mapped[int] = mapped_column(primary_key=True)
    source_name: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    source_block_stem: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    block_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("blocks.id"), nullable=True
    )
    faction: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    stage: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    parent_kind: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    act: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_act_overlay: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    region: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    mission_id: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    placement_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    visibility_default: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    placements: Mapped[list[Placement]] = relationship(
        back_populates="vz_state_overlay"
    )


class Placement(Base):
    __tablename__ = "placements"
    __table_args__ = (
        Index("ix_placements_block_type", "block_type"),
        Index("ix_placements_category_id", "category_id"),
        Index("ix_placements_cell_id", "cell_id"),
        Index("ix_placements_vz_state_overlay_id", "vz_state_overlay_id"),
        Index("ix_placements_linked_block_id", "linked_block_id"),
        Index("ix_placements_geom", "geom", postgresql_using="gist"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    entity_id: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    entity_key: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    entity_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    block_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    source_block: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    sub_block: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    pos_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    pos_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    pos_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    quat_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    quat_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    quat_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    quat_w: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    rotation_y_deg: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    rotation_y_rad: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    has_non_trivial_rotation: Mapped[Optional[bool]] = mapped_column(
        Boolean, nullable=True
    )
    ue_pos_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ue_pos_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ue_pos_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ue_yaw: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ue_pitch: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ue_roll: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    model_name_hash: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    linked_block_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("blocks.id"), nullable=True
    )
    vz_state_source: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    vz_state_overlay_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("vz_state_overlays.id"), nullable=True
    )
    type_hash: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    boot_float: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    boot_u32: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    rotation_y_sin: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    visibility_default: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    category_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("categories.id"), nullable=True
    )
    cell_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    cell_row: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    cell_col: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    distance_from_origin: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    elevation_band: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    geom = mapped_column(Geometry("POINT", srid=0), nullable=True)

    linked_block: Mapped[Optional[Block]] = relationship(foreign_keys=[linked_block_id])
    vz_state_overlay: Mapped[Optional[VzStateOverlay]] = relationship(
        back_populates="placements"
    )


# ---------------------------------------------------------------------------
# ECS (Entity Component System)
# ---------------------------------------------------------------------------

class EcsComponentType(Base):
    __tablename__ = "ecs_component_types"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    prealloc_primary: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    prealloc_secondary: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    is_runtime: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    category: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    payload_stride: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)


class EcsRecord(Base):
    __tablename__ = "ecs_records"

    id: Mapped[int] = mapped_column(primary_key=True)
    entity_key: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    comp_type_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("ecs_component_types.id"), nullable=True
    )
    comp_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    source_block: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    block_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    sub_block: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    payload_size: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    payload_hex: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    placement_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("placements.id"), nullable=True
    )
    model_name_hash: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    hibernation_u8_0: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    hibernation_u8_1: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    hibernation_f16_or_u16: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True
    )
    hibernation_u16_4: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    script_hash_0: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    script_u32_1: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    destruction_ref_key: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    destruction_u32_1: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    light_u32_0: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    light_color_r: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    light_color_g: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    light_color_b: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    light_intensity: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    light_radius: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    light_radius_ue: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    parsed_data: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)

    comp_type: Mapped[Optional[EcsComponentType]] = relationship()
    placement: Mapped[Optional[Placement]] = relationship()


class EcsSymbol(Base):
    __tablename__ = "ecs_symbols"

    id: Mapped[int] = mapped_column(primary_key=True)
    symbol: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    symbol_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    component_hint: Mapped[Optional[str]] = mapped_column(Text, nullable=True)


# ---------------------------------------------------------------------------
# ASET rows (from WAD ASET chunk)
# ---------------------------------------------------------------------------

class AsetRow(Base):
    __tablename__ = "aset_rows"

    id: Mapped[int] = mapped_column(primary_key=True)
    wad_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("wad_archives.id"), nullable=True
    )
    row_index: Mapped[int] = mapped_column(Integer, nullable=False)
    u32_0: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    u32_0_int: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    u32_1: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    u32_1_int: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    u32_2: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    u32_3: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    texture_index_hit: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    matched_texture_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    matched_block_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("blocks.id"), nullable=True
    )

    wad: Mapped[Optional[WadArchive]] = relationship(back_populates="aset_rows")


# ---------------------------------------------------------------------------
# Variant groups
# ---------------------------------------------------------------------------

class VariantGroup(Base):
    __tablename__ = "variant_groups"

    id: Mapped[int] = mapped_column(primary_key=True)
    base_asset_id: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    member_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    best_lod_block_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("blocks.id"), nullable=True
    )
    best_lod_vertices: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    members: Mapped[list[VariantGroupMember]] = relationship(back_populates="group")


class VariantGroupMember(Base):
    __tablename__ = "variant_group_members"

    id: Mapped[int] = mapped_column(primary_key=True)
    group_id: Mapped[int] = mapped_column(
        ForeignKey("variant_groups.id"), nullable=False
    )
    block_id: Mapped[int] = mapped_column(
        ForeignKey("blocks.id"), nullable=False
    )
    p_level: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    q_level: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    variant_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    group: Mapped[VariantGroup] = relationship(back_populates="members")


# ---------------------------------------------------------------------------
# Havok physics slices
# ---------------------------------------------------------------------------

class HavokSlice(Base):
    __tablename__ = "havok_slices"

    id: Mapped[int] = mapped_column(primary_key=True)
    block_id: Mapped[int] = mapped_column(
        ForeignKey("blocks.id"), nullable=False
    )
    slice_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    file_offset: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    size_written: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    preview_text: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    has_convex_hull: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    convex_hull_filename: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    havok_version: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    block: Mapped[Block] = relationship(back_populates="havok_slices")


# ---------------------------------------------------------------------------
# Dialog / narrative
# ---------------------------------------------------------------------------

class DialogFragment(Base):
    __tablename__ = "dialog_fragments"

    id: Mapped[int] = mapped_column(primary_key=True)
    block_id: Mapped[int] = mapped_column(
        ForeignKey("blocks.id"), nullable=False
    )
    fragment_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    value: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    namespace: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    key_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_mission_ref: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    is_localization: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    is_objective: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    is_subtitle: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    faction_ref: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    block: Mapped[Block] = relationship(back_populates="dialog_fragments")


# ---------------------------------------------------------------------------
# Missions & factions
# ---------------------------------------------------------------------------

class Faction(Base):
    __tablename__ = "factions"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    color_hex: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    zones: Mapped[list[Zone]] = relationship(back_populates="faction")
    splines: Mapped[list[Spline]] = relationship(back_populates="faction")
    spawners: Mapped[list[Spawner]] = relationship(back_populates="faction")


class Mission(Base):
    __tablename__ = "missions"

    id: Mapped[int] = mapped_column(primary_key=True)
    mission_id: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    faction: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    number: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    title_key: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    has_milestones: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    milestone_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    act: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    region: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    related_vz_states: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    objective_keys: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    npc_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    vo_block_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("blocks.id"), nullable=True
    )
    script_chunk_indices: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)


# ---------------------------------------------------------------------------
# Animations & skeletons
# ---------------------------------------------------------------------------

class AnimationGroup(Base):
    __tablename__ = "animation_groups"

    id: Mapped[int] = mapped_column(primary_key=True)
    slug: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    block_stem: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    block_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("blocks.id"), nullable=True
    )
    stem_numeric_id: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    bone_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    clip_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    track_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    glb_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    related_review_keys: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    skeleton_source: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    ancestor_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    block: Mapped[Optional[Block]] = relationship(back_populates="animation_groups")
    clips: Mapped[list[AnimationClip]] = relationship(back_populates="animation_group")
    skeletons: Mapped[list[Skeleton]] = relationship(back_populates="animation_group")


class AnimationClip(Base):
    __tablename__ = "animation_clips"

    id: Mapped[int] = mapped_column(primary_key=True)
    animation_group_id: Mapped[int] = mapped_column(
        ForeignKey("animation_groups.id"), nullable=False
    )
    record_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    gltf_clip_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    display_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    gltf_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    anim_name_guess: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    codec_guess: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    pelvis_ty_spread_wavelet_raw: Mapped[Optional[float]] = mapped_column(
        Float, nullable=True
    )
    pelvis_ty_spread_after_sanitize: Mapped[Optional[float]] = mapped_column(
        Float, nullable=True
    )
    pelvis_ty_sanitized: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)

    animation_group: Mapped[AnimationGroup] = relationship(back_populates="clips")


class Skeleton(Base):
    __tablename__ = "skeletons"

    id: Mapped[int] = mapped_column(primary_key=True)
    animation_group_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("animation_groups.id"), nullable=True
    )
    bone_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    source: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    track_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    ancestor_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    meta: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)

    animation_group: Mapped[Optional[AnimationGroup]] = relationship(
        back_populates="skeletons"
    )
    bones: Mapped[list[Bone]] = relationship(back_populates="skeleton")


class Bone(Base):
    __tablename__ = "bones"

    id: Mapped[int] = mapped_column(primary_key=True)
    skeleton_id: Mapped[int] = mapped_column(
        ForeignKey("skeletons.id"), nullable=False
    )
    bone_index: Mapped[int] = mapped_column(Integer, nullable=False)
    bone_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    parent_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    ref_pos_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ref_pos_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ref_pos_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ref_quat_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ref_quat_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ref_quat_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ref_quat_w: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ref_scale_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ref_scale_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    ref_scale_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)

    skeleton: Mapped[Skeleton] = relationship(back_populates="bones")


# ---------------------------------------------------------------------------
# World cells
# ---------------------------------------------------------------------------

class WorldCell(Base):
    __tablename__ = "world_cells"

    id: Mapped[int] = mapped_column(primary_key=True)
    cell_id: Mapped[int] = mapped_column(Integer, unique=True, nullable=False)
    block_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("blocks.id"), nullable=True
    )
    row: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    col: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    center_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    center_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    center_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    vertex_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    has_glb: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    has_gltf: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    cell_size_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    cell_size_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    placement_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    geom = mapped_column(Geometry("POLYGON", srid=0), nullable=True)


# ---------------------------------------------------------------------------
# Lua chunks
# ---------------------------------------------------------------------------

class LuaChunk(Base):
    __tablename__ = "lua_chunks"

    id: Mapped[int] = mapped_column(primary_key=True)
    block_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("blocks.id"), nullable=True
    )
    chunk_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    byte_offset: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    byte_length: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    bin_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    string_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    pmc_related_strings: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    all_strings: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    mission_refs: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    function_names: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)

    block: Mapped[Optional[Block]] = relationship(back_populates="lua_chunks")


# ---------------------------------------------------------------------------
# Audio
# ---------------------------------------------------------------------------

class AudioArchive(Base):
    __tablename__ = "audio_archives"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    file_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    file_size_bytes: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    stream_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    streams: Mapped[list[AudioStream]] = relationship(back_populates="archive")


class AudioStream(Base):
    __tablename__ = "audio_streams"

    id: Mapped[int] = mapped_column(primary_key=True)
    archive_id: Mapped[int] = mapped_column(
        ForeignKey("audio_archives.id"), nullable=False
    )
    stream_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    format: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    sample_rate: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    channels: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    bits_per_sample: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    duration_seconds: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    byte_rate: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    offset_in_archive: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    size_bytes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    extracted_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    archive: Mapped[AudioArchive] = relationship(back_populates="streams")


# ---------------------------------------------------------------------------
# Cutscenes
# ---------------------------------------------------------------------------

class Cutscene(Base):
    __tablename__ = "cutscenes"

    id: Mapped[int] = mapped_column(primary_key=True)
    filename: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    file_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    file_size_bytes: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    sequence_number: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    scene_code: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    character_code: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    character_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_menu_video: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    is_cutscene: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    act: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    mission_id: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    transcript: Mapped[Optional[str]] = mapped_column(Text, nullable=True)


# ---------------------------------------------------------------------------
# Save game profiles
# ---------------------------------------------------------------------------

class SaveProfile(Base):
    __tablename__ = "save_profiles"

    id: Mapped[int] = mapped_column(primary_key=True)
    source_file: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    checksum_hex: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    version: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    character_costume_index: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True
    )
    reference_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    cash: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    fuel: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    play_time_seconds: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    last_mission_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    unix_timestamp: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    lua_decompressed_chars: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True
    )
    flags_hex: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    unknown_0x0C: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    unknown_0x10: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    unknown_0x20: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    harvested_data: Mapped[list[SaveHarvestedData]] = relationship(
        back_populates="profile"
    )


class SaveHarvestedData(Base):
    __tablename__ = "save_harvested_data"

    id: Mapped[int] = mapped_column(primary_key=True)
    profile_id: Mapped[int] = mapped_column(
        ForeignKey("save_profiles.id"), nullable=False
    )
    data_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    value: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    profile: Mapped[SaveProfile] = relationship(back_populates="harvested_data")


# ---------------------------------------------------------------------------
# Roads & intersections
# ---------------------------------------------------------------------------

class Road(Base):
    __tablename__ = "roads"

    id: Mapped[int] = mapped_column(primary_key=True)
    entity_key: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    placement_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("placements.id"), nullable=True
    )
    payload_hex: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    parsed_data: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)


class RoadIntersection(Base):
    __tablename__ = "road_intersections"

    id: Mapped[int] = mapped_column(primary_key=True)
    entity_key: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    placement_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("placements.id"), nullable=True
    )
    payload_hex: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    parsed_data: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)


# ---------------------------------------------------------------------------
# Terrain tiles
# ---------------------------------------------------------------------------

class TerrainTile(Base):
    __tablename__ = "terrain_tiles"

    id: Mapped[int] = mapped_column(primary_key=True)
    toc_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    iter_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    mesh_hash: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    mesh_hash_int: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    row: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    col: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    center_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    center_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    vertex_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    is_ocean_tile: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    bbox_center_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_center_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_center_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    bbox_radius: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    geom = mapped_column(Geometry("POLYGON", srid=0), nullable=True)


# ---------------------------------------------------------------------------
# Zones, splines, spawners (world design / gameplay)
# ---------------------------------------------------------------------------

class Zone(Base):
    __tablename__ = "zones"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    zone_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    faction_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("factions.id"), nullable=True
    )
    act: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    color_hex: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    opacity: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    min_elevation: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    max_elevation: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    properties: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    geom = mapped_column(Geometry("POLYGON", srid=0), nullable=True)
    created_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    faction: Mapped[Optional[Faction]] = relationship(back_populates="zones")
    splines: Mapped[list[Spline]] = relationship(back_populates="zone")
    spawners: Mapped[list[Spawner]] = relationship(back_populates="zone")


class Spline(Base):
    __tablename__ = "splines"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    spline_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    zone_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("zones.id"), nullable=True
    )
    faction_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("factions.id"), nullable=True
    )
    is_loop: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    color_hex: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    properties: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    geom = mapped_column(Geometry("LINESTRING", srid=0), nullable=True)
    created_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    zone: Mapped[Optional[Zone]] = relationship(back_populates="splines")
    faction: Mapped[Optional[Faction]] = relationship(back_populates="splines")


class Spawner(Base):
    __tablename__ = "spawners"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    spawner_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    zone_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("zones.id"), nullable=True
    )
    faction_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("factions.id"), nullable=True
    )
    pos_x: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    pos_y: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    pos_z: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    radius: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    spawn_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    respawn_time: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    patrol_spline_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("splines.id"), nullable=True
    )
    properties: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    geom = mapped_column(Geometry("POINT", srid=0), nullable=True)
    created_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    zone: Mapped[Optional[Zone]] = relationship(back_populates="spawners")
    faction: Mapped[Optional[Faction]] = relationship(back_populates="spawners")
    patrol_spline: Mapped[Optional[Spline]] = relationship()


# ---------------------------------------------------------------------------
# Precache / resource budgets
# ---------------------------------------------------------------------------

class PrecacheSlot(Base):
    __tablename__ = "precache_slots"

    id: Mapped[int] = mapped_column(primary_key=True)
    slot_number: Mapped[int] = mapped_column(Integer, nullable=False)
    vertex_size: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    index_size: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    display_size: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    texture_size: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    surface_size: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    pshader_size: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    vshader_size: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    vertdecl_size: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    total_size: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)


# ---------------------------------------------------------------------------
# Texture index entries
# ---------------------------------------------------------------------------

class TextureIndexEntry(Base):
    __tablename__ = "texture_index_entries"

    id: Mapped[int] = mapped_column(primary_key=True)
    asset_hash: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    asset_hash_int: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    texture_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    source_block_path: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    body_offset: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    body_size: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    block_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("blocks.id"), nullable=True
    )


# ---------------------------------------------------------------------------
# Validation results
# ---------------------------------------------------------------------------

class ValidationResult(Base):
    __tablename__ = "validation_results"

    id: Mapped[int] = mapped_column(primary_key=True)
    check_name: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    block_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("blocks.id"), nullable=True
    )
    status: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    expected_value: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    actual_value: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    run_at: Mapped[Optional[str]] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
