"""Initial schema: 32 tables with PostGIS, pg_trgm, btree_gist extensions

Revision ID: 001
Revises:
Create Date: 2026-05-17

"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB
import geoalchemy2

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Enable extensions
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    op.execute("CREATE EXTENSION IF NOT EXISTS btree_gist")

    # 1. WAD Archives
    op.create_table(
        "wad_archives",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.Text, nullable=False),
        sa.Column("filename", sa.Text),
        sa.Column("file_path", sa.Text),
        sa.Column("file_size_bytes", sa.BigInteger),
        sa.Column("ffcs_version", sa.Integer),
        sa.Column("block_count", sa.Integer),
        sa.Column("indx_offset", sa.BigInteger),
        sa.Column("indx_entry_count", sa.Integer),
        sa.Column("data_offset", sa.BigInteger),
        sa.Column("data_segment_count", sa.Integer),
        sa.Column("data_size_bytes", sa.BigInteger),
        sa.Column("csum_entry_count", sa.Integer),
        sa.Column("aset_offset", sa.BigInteger),
        sa.Column("aset_entry_count", sa.Integer),
        sa.Column("aset_size_bytes", sa.BigInteger),
        sa.Column("pths_offset", sa.BigInteger),
        sa.Column("pths_entry_count", sa.Integer),
        sa.Column("pths_size_bytes", sa.BigInteger),
        sa.Column("chunk_summary", JSONB),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # 3. Categories (before blocks, since blocks FK to categories)
    op.create_table(
        "categories",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.Text, nullable=False),
        sa.Column("slug", sa.Text, unique=True, nullable=False),
        sa.Column("parent_id", sa.Integer, sa.ForeignKey("categories.id")),
        sa.Column("depth", sa.SmallInteger, server_default="0"),
        sa.Column("path", sa.Text),
        sa.Column("description", sa.Text),
        sa.Column("color_hex", sa.Text),
        sa.Column("icon", sa.Text),
        sa.Column("auto_pattern", sa.Text),
        sa.Column("sort_order", sa.Integer, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # 16. Factions (before blocks, used by zones/overlays)
    op.create_table(
        "factions",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("code", sa.Text, unique=True, nullable=False),
        sa.Column("name", sa.Text, nullable=False),
        sa.Column("color_hex", sa.Text),
        sa.Column("description", sa.Text),
    )

    # 2. Blocks
    op.create_table(
        "blocks",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("wad_id", sa.Integer, sa.ForeignKey("wad_archives.id")),
        sa.Column("block_index", sa.Integer),
        sa.Column("path", sa.Text),
        sa.Column("stem", sa.Text, unique=True),
        sa.Column("canonical_name", sa.Text),
        sa.Column("base_asset_id", sa.Text),
        sa.Column("p_level", sa.SmallInteger),
        sa.Column("q_level", sa.SmallInteger),
        sa.Column("pack", sa.Text),
        sa.Column("block_type", sa.Text),
        sa.Column("category_id", sa.Integer, sa.ForeignKey("categories.id")),
        sa.Column("review_status", sa.Text, server_default="unreviewed"),
        sa.Column("review_notes", sa.Text),
        sa.Column("reviewed_by", sa.Text),
        sa.Column("reviewed_at", sa.DateTime(timezone=True)),
        sa.Column("file_size_bytes", sa.Integer),
        sa.Column("compressed_size_bytes", sa.Integer),
        sa.Column("has_geometry", sa.Boolean),
        sa.Column("has_textures", sa.Boolean),
        sa.Column("has_havok", sa.Boolean),
        sa.Column("has_animations", sa.Boolean),
        sa.Column("has_lua", sa.Boolean),
        sa.Column("has_audio", sa.Boolean),
        sa.Column("has_dialog", sa.Boolean),
        sa.Column("thumbnail_path", sa.Text),
        sa.Column("review_dir_path", sa.Text),
        sa.Column("glb_path", sa.Text),
        sa.Column("gltf_path", sa.Text),
        sa.Column("obj_path", sa.Text),
        sa.Column("variant_type", sa.Text),
        sa.Column("variant_tags", JSONB),
        sa.Column("texture_channel_hint", sa.Text),
        sa.Column("faction_hint", sa.Text),
        sa.Column("region_hint", sa.Text),
        sa.Column("ucfx_offset_count", sa.Integer),
        sa.Column("primary_ucfx_offset", sa.Integer),
        sa.Column("ucfx_offsets", JSONB),
        sa.Column("tag_occurrences", JSONB),
        sa.Column("strings_sample", JSONB),
        sa.Column("geom_chunk_trees", JSONB),
        sa.Column("raw_ucfx_json", JSONB),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_blocks_block_type", "blocks", ["block_type"])
    op.create_index("ix_blocks_category_id", "blocks", ["category_id"])
    op.create_index("ix_blocks_review_status", "blocks", ["review_status"])
    op.create_index("ix_blocks_canonical_name", "blocks", ["canonical_name"])
    op.create_index("ix_blocks_base_asset_id", "blocks", ["base_asset_id"])
    op.create_index("ix_blocks_faction_hint", "blocks", ["faction_hint"])
    op.create_index("ix_blocks_region_hint", "blocks", ["region_hint"])
    op.create_index("ix_blocks_tag_occurrences", "blocks", ["tag_occurrences"], postgresql_using="gin")
    op.create_index("ix_blocks_strings_sample", "blocks", ["strings_sample"], postgresql_using="gin")
    op.create_index(
        "ix_blocks_canonical_name_trgm", "blocks", ["canonical_name"],
        postgresql_using="gin", postgresql_ops={"canonical_name": "gin_trgm_ops"},
    )

    # 4. Tags
    op.create_table(
        "tags",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.Text, nullable=False),
        sa.Column("slug", sa.Text, unique=True, nullable=False),
        sa.Column("color_hex", sa.Text),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_table(
        "block_tags",
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id"), primary_key=True),
        sa.Column("tag_id", sa.Integer, sa.ForeignKey("tags.id"), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # 5. Block Mesh Metadata
    op.create_table(
        "block_mesh_meta",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id"), unique=True, nullable=False),
        sa.Column("total_vertices", sa.Integer),
        sa.Column("total_faces", sa.Integer),
        sa.Column("topology", sa.Text),
        sa.Column("extraction_method", sa.Text),
        sa.Column("mesh_group_count", sa.Integer),
        sa.Column("transparent_count", sa.Integer),
        sa.Column("lod_mode", sa.Text),
        sa.Column("material_indices", JSONB),
        sa.Column("notes", sa.Text),
        sa.Column("bbox_volume", sa.Float),
        sa.Column("bbox_min_x", sa.Float),
        sa.Column("bbox_min_y", sa.Float),
        sa.Column("bbox_min_z", sa.Float),
        sa.Column("bbox_max_x", sa.Float),
        sa.Column("bbox_max_y", sa.Float),
        sa.Column("bbox_max_z", sa.Float),
        sa.Column("bbox_center_x", sa.Float),
        sa.Column("bbox_center_y", sa.Float),
        sa.Column("bbox_center_z", sa.Float),
        sa.Column("extent_x", sa.Float),
        sa.Column("extent_y", sa.Float),
        sa.Column("extent_z", sa.Float),
        sa.Column("max_extent", sa.Float),
        sa.Column("is_flat", sa.Boolean),
        sa.Column("raw_meta_json", JSONB),
    )

    # 6. Submeshes
    op.create_table(
        "submeshes",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id"), nullable=False),
        sa.Column("submesh_index", sa.Integer),
        sa.Column("obj_filename", sa.Text),
        sa.Column("vertex_count", sa.Integer),
        sa.Column("face_count", sa.Integer),
        sa.Column("stride_bytes", sa.Integer),
        sa.Column("vertex_format", sa.Text),
        sa.Column("material_index", sa.Integer),
        sa.Column("is_transparent", sa.Boolean),
        sa.Column("transparency_flag", sa.Float),
        sa.Column("lod_group", sa.Integer),
        sa.Column("lod_rank", sa.Integer),
        sa.Column("is_vehicle_lod", sa.Boolean),
        sa.Column("lod_alternatives", JSONB),
        sa.Column("mesh_group_id", sa.Integer),
        sa.Column("mesh_draw_index", sa.Integer),
        sa.Column("prmt_draw_index", sa.Integer),
        sa.Column("texture_diffuse", sa.Text),
        sa.Column("texture_normal", sa.Text),
        sa.Column("texture_specular", sa.Text),
        sa.Column("hier_node_idx", sa.Integer),
        sa.Column("damage_state", sa.Text),
        sa.Column("instanced_from", sa.Integer),
        sa.Column("bbox_min_x", sa.Float),
        sa.Column("bbox_min_y", sa.Float),
        sa.Column("bbox_min_z", sa.Float),
        sa.Column("bbox_max_x", sa.Float),
        sa.Column("bbox_max_y", sa.Float),
        sa.Column("bbox_max_z", sa.Float),
        sa.Column("bbox_volume", sa.Float),
        sa.Column("prmg_bbox_min_x", sa.Float),
        sa.Column("prmg_bbox_min_y", sa.Float),
        sa.Column("prmg_bbox_min_z", sa.Float),
        sa.Column("prmg_bbox_max_x", sa.Float),
        sa.Column("prmg_bbox_max_y", sa.Float),
        sa.Column("prmg_bbox_max_z", sa.Float),
        sa.Column("world_translation_x", sa.Float),
        sa.Column("world_translation_y", sa.Float),
        sa.Column("world_translation_z", sa.Float),
        sa.Column("world_rotation_3x3", JSONB),
        sa.Column("hier_instance_nodes", JSONB),
        sa.Column("vb_file_offset", sa.Integer),
        sa.Column("vb_len", sa.Integer),
        sa.Column("ib_file_offset", sa.Integer),
        sa.Column("ib_len", sa.Integer),
        sa.Column("n_indices", sa.Integer),
        sa.Column("index_max", sa.Integer),
    )
    op.create_index("ix_submeshes_block_id", "submeshes", ["block_id"])

    # 7. Textures
    op.create_table(
        "textures",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.Text, unique=True, nullable=False),
        sa.Column("asset_hash", sa.Text),
        sa.Column("asset_hash_int", sa.BigInteger),
        sa.Column("width", sa.Integer),
        sa.Column("height", sa.Integer),
        sa.Column("mip_count", sa.Integer),
        sa.Column("fourcc", sa.Text),
        sa.Column("total_size_bytes", sa.Integer),
        sa.Column("is_global", sa.Boolean),
        sa.Column("texture_channel", sa.Text),
        sa.Column("base_texture_name", sa.Text),
        sa.Column("source_block_count", sa.Integer),
        sa.Column("first_seen_block_id", sa.Integer, sa.ForeignKey("blocks.id")),
    )
    op.create_table(
        "block_textures",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id"), nullable=False),
        sa.Column("texture_id", sa.Integer, sa.ForeignKey("textures.id"), nullable=False),
        sa.Column("is_shared", sa.Boolean),
        sa.Column("is_local", sa.Boolean),
        sa.Column("body_offset", sa.Integer),
        sa.Column("body_size", sa.Integer),
    )
    op.create_index("ix_block_textures_block_id", "block_textures", ["block_id"])
    op.create_index("ix_block_textures_texture_id", "block_textures", ["texture_id"])

    # 9. VZ State Overlays (before placements which FK to it)
    op.create_table(
        "vz_state_overlays",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("source_name", sa.Text, unique=True),
        sa.Column("source_block_stem", sa.Text),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id")),
        sa.Column("faction", sa.Text),
        sa.Column("stage", sa.Text),
        sa.Column("parent_kind", sa.Text),
        sa.Column("act", sa.Text),
        sa.Column("is_act_overlay", sa.Boolean),
        sa.Column("region", sa.Text),
        sa.Column("mission_id", sa.Text),
        sa.Column("placement_count", sa.Integer),
        sa.Column("visibility_default", sa.Boolean),
        sa.Column("description", sa.Text),
    )

    # 8. Placements
    op.create_table(
        "placements",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("entity_id", sa.Text),
        sa.Column("entity_key", sa.Integer),
        sa.Column("entity_name", sa.Text),
        sa.Column("block_type", sa.Text),
        sa.Column("source_block", sa.Text),
        sa.Column("sub_block", sa.Integer),
        sa.Column("pos_x", sa.Float),
        sa.Column("pos_y", sa.Float),
        sa.Column("pos_z", sa.Float),
        sa.Column("quat_x", sa.Float),
        sa.Column("quat_y", sa.Float),
        sa.Column("quat_z", sa.Float),
        sa.Column("quat_w", sa.Float),
        sa.Column("rotation_y_deg", sa.Float),
        sa.Column("rotation_y_rad", sa.Float),
        sa.Column("has_non_trivial_rotation", sa.Boolean),
        sa.Column("ue_pos_x", sa.Float),
        sa.Column("ue_pos_y", sa.Float),
        sa.Column("ue_pos_z", sa.Float),
        sa.Column("ue_yaw", sa.Float),
        sa.Column("ue_pitch", sa.Float),
        sa.Column("ue_roll", sa.Float),
        sa.Column("model_name_hash", sa.Text),
        sa.Column("linked_block_id", sa.Integer, sa.ForeignKey("blocks.id")),
        sa.Column("vz_state_source", sa.Text),
        sa.Column("vz_state_overlay_id", sa.Integer, sa.ForeignKey("vz_state_overlays.id")),
        sa.Column("type_hash", sa.Text),
        sa.Column("boot_float", sa.Float),
        sa.Column("boot_u32", sa.Text),
        sa.Column("rotation_y_sin", sa.Float),
        sa.Column("visibility_default", sa.Boolean),
        sa.Column("category_id", sa.Integer, sa.ForeignKey("categories.id")),
        sa.Column("cell_id", sa.Integer),
        sa.Column("cell_row", sa.Integer),
        sa.Column("cell_col", sa.Integer),
        sa.Column("distance_from_origin", sa.Float),
        sa.Column("elevation_band", sa.Text),
        sa.Column("geom", geoalchemy2.Geometry("POINT", srid=0)),
    )
    op.create_index("ix_placements_geom", "placements", ["geom"], postgresql_using="gist")
    op.create_index("ix_placements_block_type", "placements", ["block_type"])
    op.create_index("ix_placements_category_id", "placements", ["category_id"])
    op.create_index("ix_placements_cell_id", "placements", ["cell_id"])
    op.create_index("ix_placements_vz_state_overlay_id", "placements", ["vz_state_overlay_id"])
    op.create_index("ix_placements_linked_block_id", "placements", ["linked_block_id"])
    op.create_index(
        "ix_placements_entity_name_trgm", "placements", ["entity_name"],
        postgresql_using="gin", postgresql_ops={"entity_name": "gin_trgm_ops"},
    )

    # 10. ECS Component Types
    op.create_table(
        "ecs_component_types",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.Text, unique=True, nullable=False),
        sa.Column("prealloc_primary", sa.Integer),
        sa.Column("prealloc_secondary", sa.Integer),
        sa.Column("is_runtime", sa.Boolean, server_default="false"),
        sa.Column("category", sa.Text),
        sa.Column("description", sa.Text),
        sa.Column("payload_stride", sa.Integer),
    )

    # 10b. ECS Records
    op.create_table(
        "ecs_records",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("entity_key", sa.Integer),
        sa.Column("comp_type_id", sa.Integer, sa.ForeignKey("ecs_component_types.id")),
        sa.Column("comp_name", sa.Text),
        sa.Column("source_block", sa.Text),
        sa.Column("block_type", sa.Text),
        sa.Column("sub_block", sa.Integer),
        sa.Column("payload_size", sa.Integer),
        sa.Column("payload_hex", sa.Text),
        sa.Column("placement_id", sa.Integer, sa.ForeignKey("placements.id")),
        sa.Column("model_name_hash", sa.Text),
        sa.Column("hibernation_u8_0", sa.SmallInteger),
        sa.Column("hibernation_u8_1", sa.SmallInteger),
        sa.Column("hibernation_f16_or_u16", sa.Integer),
        sa.Column("hibernation_u16_4", sa.Integer),
        sa.Column("script_hash_0", sa.Text),
        sa.Column("script_u32_1", sa.Integer),
        sa.Column("destruction_ref_key", sa.Text),
        sa.Column("destruction_u32_1", sa.Integer),
        sa.Column("light_u32_0", sa.Integer),
        sa.Column("light_color_r", sa.SmallInteger),
        sa.Column("light_color_g", sa.SmallInteger),
        sa.Column("light_color_b", sa.SmallInteger),
        sa.Column("light_intensity", sa.Float),
        sa.Column("light_radius", sa.Float),
        sa.Column("light_radius_ue", sa.Float),
        sa.Column("parsed_data", JSONB),
    )
    op.create_index("ix_ecs_records_entity_key", "ecs_records", ["entity_key"])
    op.create_index("ix_ecs_records_comp_type_id", "ecs_records", ["comp_type_id"])
    op.create_index("ix_ecs_records_placement_id", "ecs_records", ["placement_id"])

    # 11. ASET Dependencies
    op.create_table(
        "aset_rows",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("wad_id", sa.Integer, sa.ForeignKey("wad_archives.id")),
        sa.Column("row_index", sa.Integer),
        sa.Column("u32_0", sa.Text),
        sa.Column("u32_0_int", sa.BigInteger),
        sa.Column("u32_1", sa.Text),
        sa.Column("u32_1_int", sa.BigInteger),
        sa.Column("u32_2", sa.Text),
        sa.Column("u32_3", sa.Integer),
        sa.Column("texture_index_hit", sa.Boolean),
        sa.Column("matched_texture_name", sa.Text),
        sa.Column("matched_block_id", sa.Integer, sa.ForeignKey("blocks.id")),
    )
    op.create_index("ix_aset_rows_u32_0_int", "aset_rows", ["u32_0_int"])
    op.create_index("ix_aset_rows_matched_block_id", "aset_rows", ["matched_block_id"])

    # 12. Variant Groups
    op.create_table(
        "variant_groups",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("base_asset_id", sa.Text, unique=True),
        sa.Column("member_count", sa.Integer),
        sa.Column("best_lod_block_id", sa.Integer, sa.ForeignKey("blocks.id")),
        sa.Column("best_lod_vertices", sa.Integer),
    )
    op.create_table(
        "variant_group_members",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("group_id", sa.Integer, sa.ForeignKey("variant_groups.id"), nullable=False),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id"), nullable=False),
        sa.Column("p_level", sa.SmallInteger),
        sa.Column("q_level", sa.SmallInteger),
        sa.Column("variant_type", sa.Text),
    )
    op.create_index("ix_variant_group_members_group_id", "variant_group_members", ["group_id"])
    op.create_index("ix_variant_group_members_block_id", "variant_group_members", ["block_id"])

    # 13. Havok Physics Slices
    op.create_table(
        "havok_slices",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id"), nullable=False),
        sa.Column("slice_index", sa.Integer),
        sa.Column("file_offset", sa.Integer),
        sa.Column("size_written", sa.Integer),
        sa.Column("preview_text", sa.Text),
        sa.Column("has_convex_hull", sa.Boolean),
        sa.Column("convex_hull_filename", sa.Text),
        sa.Column("havok_version", sa.Text),
    )
    op.create_index("ix_havok_slices_block_id", "havok_slices", ["block_id"])

    # 14. Dialog and Localization
    op.create_table(
        "dialog_fragments",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id"), nullable=False),
        sa.Column("fragment_type", sa.Text),
        sa.Column("value", sa.Text),
        sa.Column("namespace", sa.Text),
        sa.Column("key_path", sa.Text),
        sa.Column("is_mission_ref", sa.Boolean),
        sa.Column("is_localization", sa.Boolean),
        sa.Column("is_objective", sa.Boolean),
        sa.Column("is_subtitle", sa.Boolean),
        sa.Column("faction_ref", sa.Text),
    )
    op.create_index("ix_dialog_fragments_block_id", "dialog_fragments", ["block_id"])
    op.create_index("ix_dialog_fragments_namespace", "dialog_fragments", ["namespace"])

    # 15. Missions and Contracts
    op.create_table(
        "missions",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("mission_id", sa.Text, unique=True, nullable=False),
        sa.Column("faction", sa.Text),
        sa.Column("type", sa.Text),
        sa.Column("number", sa.Integer),
        sa.Column("title_key", sa.Text),
        sa.Column("has_milestones", sa.Boolean),
        sa.Column("milestone_count", sa.Integer),
        sa.Column("act", sa.Text),
        sa.Column("region", sa.Text),
        sa.Column("related_vz_states", JSONB),
        sa.Column("objective_keys", JSONB),
        sa.Column("npc_name", sa.Text),
        sa.Column("vo_block_id", sa.Integer, sa.ForeignKey("blocks.id")),
        sa.Column("script_chunk_indices", JSONB),
    )
    op.create_index("ix_missions_faction", "missions", ["faction"])
    op.create_index("ix_missions_type", "missions", ["type"])
    op.create_index("ix_missions_act", "missions", ["act"])

    # 17. Animation Groups
    op.create_table(
        "animation_groups",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("slug", sa.Text, unique=True),
        sa.Column("block_stem", sa.Text),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id")),
        sa.Column("stem_numeric_id", sa.Text),
        sa.Column("bone_count", sa.Integer),
        sa.Column("clip_count", sa.Integer),
        sa.Column("track_count", sa.Integer),
        sa.Column("glb_path", sa.Text),
        sa.Column("related_review_keys", JSONB),
        sa.Column("skeleton_source", sa.Text),
        sa.Column("ancestor_count", sa.Integer),
    )
    op.create_table(
        "animation_clips",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("animation_group_id", sa.Integer, sa.ForeignKey("animation_groups.id"), nullable=False),
        sa.Column("record_index", sa.Integer),
        sa.Column("gltf_clip_index", sa.Integer),
        sa.Column("display_name", sa.Text),
        sa.Column("gltf_name", sa.Text),
        sa.Column("anim_name_guess", sa.Text),
        sa.Column("codec_guess", sa.Text),
        sa.Column("pelvis_ty_spread_wavelet_raw", sa.Float),
        sa.Column("pelvis_ty_spread_after_sanitize", sa.Float),
        sa.Column("pelvis_ty_sanitized", JSONB),
    )
    op.create_index("ix_animation_clips_group_id", "animation_clips", ["animation_group_id"])

    # 18. Skeletons and Bones
    op.create_table(
        "skeletons",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("animation_group_id", sa.Integer, sa.ForeignKey("animation_groups.id")),
        sa.Column("bone_count", sa.Integer),
        sa.Column("source", sa.Text),
        sa.Column("track_count", sa.Integer),
        sa.Column("ancestor_count", sa.Integer),
        sa.Column("meta", JSONB),
    )
    op.create_table(
        "bones",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("skeleton_id", sa.Integer, sa.ForeignKey("skeletons.id"), nullable=False),
        sa.Column("bone_index", sa.Integer),
        sa.Column("bone_name", sa.Text),
        sa.Column("parent_index", sa.Integer),
        sa.Column("ref_pos_x", sa.Float),
        sa.Column("ref_pos_y", sa.Float),
        sa.Column("ref_pos_z", sa.Float),
        sa.Column("ref_quat_x", sa.Float),
        sa.Column("ref_quat_y", sa.Float),
        sa.Column("ref_quat_z", sa.Float),
        sa.Column("ref_quat_w", sa.Float),
        sa.Column("ref_scale_x", sa.Float),
        sa.Column("ref_scale_y", sa.Float),
        sa.Column("ref_scale_z", sa.Float),
    )
    op.create_index("ix_bones_skeleton_id", "bones", ["skeleton_id"])

    # 19. C3 World Cells
    op.create_table(
        "world_cells",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("cell_id", sa.Integer, unique=True),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id")),
        sa.Column("row", sa.Integer),
        sa.Column("col", sa.Integer),
        sa.Column("center_x", sa.Float),
        sa.Column("center_y", sa.Float),
        sa.Column("center_z", sa.Float),
        sa.Column("vertex_count", sa.Integer),
        sa.Column("has_glb", sa.Boolean),
        sa.Column("has_gltf", sa.Boolean),
        sa.Column("cell_size_x", sa.Float),
        sa.Column("cell_size_z", sa.Float),
        sa.Column("placement_count", sa.Integer),
        sa.Column("geom", geoalchemy2.Geometry("POLYGON", srid=0)),
    )
    op.create_index("ix_world_cells_geom", "world_cells", ["geom"], postgresql_using="gist")

    # 20. Lua Script Chunks
    op.create_table(
        "lua_chunks",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id"), nullable=False),
        sa.Column("chunk_index", sa.Integer),
        sa.Column("byte_offset", sa.Integer),
        sa.Column("byte_length", sa.Integer),
        sa.Column("bin_path", sa.Text),
        sa.Column("string_count", sa.Integer),
        sa.Column("pmc_related_strings", JSONB),
        sa.Column("all_strings", JSONB),
        sa.Column("mission_refs", JSONB),
        sa.Column("function_names", JSONB),
    )
    op.create_index("ix_lua_chunks_block_id", "lua_chunks", ["block_id"])

    # 21. Audio Assets
    op.create_table(
        "audio_archives",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.Text),
        sa.Column("file_path", sa.Text),
        sa.Column("file_size_bytes", sa.BigInteger),
        sa.Column("stream_count", sa.Integer),
    )
    op.create_table(
        "audio_streams",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("archive_id", sa.Integer, sa.ForeignKey("audio_archives.id"), nullable=False),
        sa.Column("stream_index", sa.Integer),
        sa.Column("format", sa.Text),
        sa.Column("sample_rate", sa.Integer),
        sa.Column("channels", sa.Integer),
        sa.Column("bits_per_sample", sa.Integer),
        sa.Column("duration_seconds", sa.Float),
        sa.Column("byte_rate", sa.Integer),
        sa.Column("offset_in_archive", sa.BigInteger),
        sa.Column("size_bytes", sa.Integer),
        sa.Column("extracted_path", sa.Text),
    )
    op.create_index("ix_audio_streams_archive_id", "audio_streams", ["archive_id"])

    # 22. Cutscenes / Movies
    op.create_table(
        "cutscenes",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("filename", sa.Text),
        sa.Column("file_path", sa.Text),
        sa.Column("file_size_bytes", sa.BigInteger),
        sa.Column("sequence_number", sa.Integer),
        sa.Column("scene_code", sa.Text),
        sa.Column("character_code", sa.Text),
        sa.Column("character_name", sa.Text),
        sa.Column("is_menu_video", sa.Boolean),
        sa.Column("is_cutscene", sa.Boolean),
        sa.Column("act", sa.Text),
        sa.Column("description", sa.Text),
        sa.Column("mission_id", sa.Text),
        sa.Column("transcript", sa.Text),
    )

    # 23. Save Game Profiles
    op.create_table(
        "save_profiles",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("source_file", sa.Text),
        sa.Column("checksum_hex", sa.Text),
        sa.Column("version", sa.Integer),
        sa.Column("character_costume_index", sa.Integer),
        sa.Column("reference_name", sa.Text),
        sa.Column("cash", sa.Integer),
        sa.Column("fuel", sa.Integer),
        sa.Column("play_time_seconds", sa.Integer),
        sa.Column("last_mission_name", sa.Text),
        sa.Column("unix_timestamp", sa.Integer),
        sa.Column("lua_decompressed_chars", sa.Integer),
        sa.Column("flags_hex", sa.Text),
        sa.Column("unknown_0x0c", sa.Integer),
        sa.Column("unknown_0x10", sa.Integer),
        sa.Column("unknown_0x20", sa.Integer),
    )
    op.create_table(
        "save_harvested_data",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("profile_id", sa.Integer, sa.ForeignKey("save_profiles.id"), nullable=False),
        sa.Column("data_type", sa.Text),
        sa.Column("value", sa.Text),
    )
    op.create_index("ix_save_harvested_data_profile_id", "save_harvested_data", ["profile_id"])
    op.create_index("ix_save_harvested_data_data_type", "save_harvested_data", ["data_type"])

    # 24. Road Network
    op.create_table(
        "roads",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("entity_key", sa.Integer),
        sa.Column("placement_id", sa.Integer, sa.ForeignKey("placements.id")),
        sa.Column("payload_hex", sa.Text),
        sa.Column("parsed_data", JSONB),
    )
    op.create_index("ix_roads_entity_key", "roads", ["entity_key"])
    op.create_table(
        "road_intersections",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("entity_key", sa.Integer),
        sa.Column("placement_id", sa.Integer, sa.ForeignKey("placements.id")),
        sa.Column("payload_hex", sa.Text),
        sa.Column("parsed_data", JSONB),
    )
    op.create_index("ix_road_intersections_entity_key", "road_intersections", ["entity_key"])

    # 25. Terrain Tiles
    op.create_table(
        "terrain_tiles",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("toc_index", sa.Integer),
        sa.Column("iter_index", sa.Integer),
        sa.Column("mesh_hash", sa.Text),
        sa.Column("mesh_hash_int", sa.BigInteger),
        sa.Column("row", sa.Integer),
        sa.Column("col", sa.Integer),
        sa.Column("center_x", sa.Float),
        sa.Column("center_z", sa.Float),
        sa.Column("vertex_count", sa.Integer),
        sa.Column("is_ocean_tile", sa.Boolean),
        sa.Column("bbox_center_x", sa.Float),
        sa.Column("bbox_center_y", sa.Float),
        sa.Column("bbox_center_z", sa.Float),
        sa.Column("bbox_radius", sa.Float),
        sa.Column("geom", geoalchemy2.Geometry("POLYGON", srid=0)),
    )
    op.create_index("ix_terrain_tiles_geom", "terrain_tiles", ["geom"], postgresql_using="gist")

    # 26. Polygon Zones
    op.create_table(
        "zones",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.Text),
        sa.Column("zone_type", sa.Text),
        sa.Column("faction_id", sa.Integer, sa.ForeignKey("factions.id")),
        sa.Column("act", sa.Text),
        sa.Column("description", sa.Text),
        sa.Column("color_hex", sa.Text),
        sa.Column("opacity", sa.Float),
        sa.Column("min_elevation", sa.Float),
        sa.Column("max_elevation", sa.Float),
        sa.Column("is_active", sa.Boolean, server_default="true"),
        sa.Column("sort_order", sa.Integer),
        sa.Column("properties", JSONB),
        sa.Column("geom", geoalchemy2.Geometry("POLYGON", srid=0)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_zones_geom", "zones", ["geom"], postgresql_using="gist")
    op.create_index("ix_zones_zone_type", "zones", ["zone_type"])

    # 27. Splines / Paths
    op.create_table(
        "splines",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.Text),
        sa.Column("spline_type", sa.Text),
        sa.Column("zone_id", sa.Integer, sa.ForeignKey("zones.id")),
        sa.Column("faction_id", sa.Integer, sa.ForeignKey("factions.id")),
        sa.Column("is_loop", sa.Boolean),
        sa.Column("description", sa.Text),
        sa.Column("color_hex", sa.Text),
        sa.Column("properties", JSONB),
        sa.Column("geom", geoalchemy2.Geometry("LINESTRING", srid=0)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_splines_geom", "splines", ["geom"], postgresql_using="gist")
    op.create_index("ix_splines_spline_type", "splines", ["spline_type"])

    # 28. Spawner Definitions
    op.create_table(
        "spawners",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.Text),
        sa.Column("spawner_type", sa.Text),
        sa.Column("zone_id", sa.Integer, sa.ForeignKey("zones.id")),
        sa.Column("faction_id", sa.Integer, sa.ForeignKey("factions.id")),
        sa.Column("pos_x", sa.Float),
        sa.Column("pos_y", sa.Float),
        sa.Column("pos_z", sa.Float),
        sa.Column("radius", sa.Float),
        sa.Column("spawn_count", sa.Integer),
        sa.Column("respawn_time", sa.Float),
        sa.Column("patrol_spline_id", sa.Integer, sa.ForeignKey("splines.id")),
        sa.Column("properties", JSONB),
        sa.Column("geom", geoalchemy2.Geometry("POINT", srid=0)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_spawners_geom", "spawners", ["geom"], postgresql_using="gist")
    op.create_index("ix_spawners_spawner_type", "spawners", ["spawner_type"])

    # 29. Precache Data
    op.create_table(
        "precache_slots",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("slot_number", sa.Integer, unique=True),
        sa.Column("vertex_size", sa.BigInteger),
        sa.Column("index_size", sa.BigInteger),
        sa.Column("display_size", sa.BigInteger),
        sa.Column("texture_size", sa.BigInteger),
        sa.Column("surface_size", sa.BigInteger),
        sa.Column("pshader_size", sa.BigInteger),
        sa.Column("vshader_size", sa.BigInteger),
        sa.Column("vertdecl_size", sa.BigInteger),
        sa.Column("total_size", sa.BigInteger),
    )

    # 30. ECS Manifest Symbols
    op.create_table(
        "ecs_symbols",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("symbol", sa.Text),
        sa.Column("symbol_type", sa.Text),
        sa.Column("component_hint", sa.Text),
    )
    op.create_index("ix_ecs_symbols_symbol", "ecs_symbols", ["symbol"])
    op.create_index("ix_ecs_symbols_component_hint", "ecs_symbols", ["component_hint"])

    # 31. Texture Streaming Index
    op.create_table(
        "texture_index_entries",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("asset_hash", sa.Text),
        sa.Column("asset_hash_int", sa.BigInteger),
        sa.Column("texture_name", sa.Text),
        sa.Column("source_block_path", sa.Text),
        sa.Column("body_offset", sa.Integer),
        sa.Column("body_size", sa.Integer),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id")),
    )
    op.create_index("ix_texture_index_entries_asset_hash_int", "texture_index_entries", ["asset_hash_int"])
    op.create_index("ix_texture_index_entries_block_id", "texture_index_entries", ["block_id"])

    # 32. Consistency Checks / Validation Log
    op.create_table(
        "validation_results",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("check_name", sa.Text),
        sa.Column("block_id", sa.Integer, sa.ForeignKey("blocks.id")),
        sa.Column("status", sa.Text),
        sa.Column("expected_value", sa.Text),
        sa.Column("actual_value", sa.Text),
        sa.Column("message", sa.Text),
        sa.Column("run_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_validation_results_check_name", "validation_results", ["check_name"])
    op.create_index("ix_validation_results_block_id", "validation_results", ["block_id"])
    op.create_index("ix_validation_results_status", "validation_results", ["status"])


def downgrade() -> None:
    op.drop_table("validation_results")
    op.drop_table("texture_index_entries")
    op.drop_table("ecs_symbols")
    op.drop_table("precache_slots")
    op.drop_table("spawners")
    op.drop_table("splines")
    op.drop_table("zones")
    op.drop_table("terrain_tiles")
    op.drop_table("road_intersections")
    op.drop_table("roads")
    op.drop_table("save_harvested_data")
    op.drop_table("save_profiles")
    op.drop_table("cutscenes")
    op.drop_table("audio_streams")
    op.drop_table("audio_archives")
    op.drop_table("lua_chunks")
    op.drop_table("world_cells")
    op.drop_table("bones")
    op.drop_table("skeletons")
    op.drop_table("animation_clips")
    op.drop_table("animation_groups")
    op.drop_table("missions")
    op.drop_table("dialog_fragments")
    op.drop_table("havok_slices")
    op.drop_table("variant_group_members")
    op.drop_table("variant_groups")
    op.drop_table("aset_rows")
    op.drop_table("ecs_records")
    op.drop_table("ecs_component_types")
    op.drop_table("placements")
    op.drop_table("vz_state_overlays")
    op.drop_table("block_textures")
    op.drop_table("textures")
    op.drop_table("submeshes")
    op.drop_table("block_mesh_meta")
    op.drop_table("block_tags")
    op.drop_table("tags")
    op.drop_table("blocks")
    op.drop_table("factions")
    op.drop_table("categories")
    op.drop_table("wad_archives")

    op.execute("DROP EXTENSION IF EXISTS btree_gist")
    op.execute("DROP EXTENSION IF EXISTS pg_trgm")
    op.execute("DROP EXTENSION IF EXISTS postgis")
