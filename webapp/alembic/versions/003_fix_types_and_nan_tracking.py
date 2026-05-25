"""Fix column types (BigInteger, Float) and add NaN tracking columns

Revision ID: 003
Revises: 002
Create Date: 2026-05-17

"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- Type fixes ---

    op.alter_column(
        "submeshes", "material_index",
        type_=sa.BigInteger(),
        existing_type=sa.Integer(),
        existing_nullable=True,
    )

    op.alter_column(
        "placements", "entity_key",
        type_=sa.BigInteger(),
        existing_type=sa.Integer(),
        existing_nullable=True,
    )

    op.alter_column(
        "ecs_records", "entity_key",
        type_=sa.BigInteger(),
        existing_type=sa.Integer(),
        existing_nullable=True,
    )

    op.alter_column(
        "ecs_records", "light_color_r",
        type_=sa.Float(),
        existing_type=sa.SmallInteger(),
        existing_nullable=True,
    )

    op.alter_column(
        "ecs_records", "light_color_g",
        type_=sa.Float(),
        existing_type=sa.SmallInteger(),
        existing_nullable=True,
    )

    op.alter_column(
        "ecs_records", "light_color_b",
        type_=sa.Float(),
        existing_type=sa.SmallInteger(),
        existing_nullable=True,
    )

    op.alter_column(
        "lua_chunks", "block_id",
        nullable=True,
        existing_type=sa.Integer(),
        existing_nullable=False,
    )

    # --- New columns ---

    op.add_column(
        "block_mesh_meta",
        sa.Column("has_nan_normals", sa.Boolean(), server_default="false", nullable=True),
    )
    op.add_column(
        "block_mesh_meta",
        sa.Column("has_nan_uvs", sa.Boolean(), server_default="false", nullable=True),
    )
    op.add_column(
        "block_mesh_meta",
        sa.Column("mesh_meta_path", sa.Text(), nullable=True),
    )
    op.add_column(
        "block_mesh_meta",
        sa.Column("mesh_meta_size_bytes", sa.BigInteger(), nullable=True),
    )

    op.add_column(
        "submeshes",
        sa.Column("nan_uv_count", sa.Integer(), server_default="0", nullable=True),
    )
    op.add_column(
        "submeshes",
        sa.Column("nan_normal_count", sa.Integer(), server_default="0", nullable=True),
    )


def downgrade() -> None:
    # --- Drop new columns ---

    op.drop_column("submeshes", "nan_normal_count")
    op.drop_column("submeshes", "nan_uv_count")

    op.drop_column("block_mesh_meta", "mesh_meta_size_bytes")
    op.drop_column("block_mesh_meta", "mesh_meta_path")
    op.drop_column("block_mesh_meta", "has_nan_uvs")
    op.drop_column("block_mesh_meta", "has_nan_normals")

    # --- Revert type fixes ---

    op.alter_column(
        "lua_chunks", "block_id",
        nullable=False,
        existing_type=sa.Integer(),
        existing_nullable=True,
    )

    op.alter_column(
        "ecs_records", "light_color_b",
        type_=sa.SmallInteger(),
        existing_type=sa.Float(),
        existing_nullable=True,
    )

    op.alter_column(
        "ecs_records", "light_color_g",
        type_=sa.SmallInteger(),
        existing_type=sa.Float(),
        existing_nullable=True,
    )

    op.alter_column(
        "ecs_records", "light_color_r",
        type_=sa.SmallInteger(),
        existing_type=sa.Float(),
        existing_nullable=True,
    )

    op.alter_column(
        "ecs_records", "entity_key",
        type_=sa.Integer(),
        existing_type=sa.BigInteger(),
        existing_nullable=True,
    )

    op.alter_column(
        "placements", "entity_key",
        type_=sa.Integer(),
        existing_type=sa.BigInteger(),
        existing_nullable=True,
    )

    op.alter_column(
        "submeshes", "material_index",
        type_=sa.Integer(),
        existing_type=sa.BigInteger(),
        existing_nullable=True,
    )
