"""Havok hull extraction: structured slice census + per-hull table

Adds the structured fields produced by the exact LE decoder
(mercs2_formats::havok, manifest schema "mercs2_havok/2") so the destructible
subdivision analysis is queryable: per-slice class census + per-kind counts on
havok_slices, and a havok_hulls table with one row per convex break-piece hull.

Revision ID: 004
Revises: 003
Create Date: 2026-06-21

"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "004"
down_revision: Union[str, None] = "003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("havok_slices", sa.Column("class_counts", sa.JSON(), nullable=True))
    op.add_column("havok_slices", sa.Column("convex_hull_count", sa.Integer(), nullable=True))
    op.add_column("havok_slices", sa.Column("box_count", sa.Integer(), nullable=True))
    op.add_column("havok_slices", sa.Column("mopp_count", sa.Integer(), nullable=True))
    op.add_column("havok_slices", sa.Column("mesh_count", sa.Integer(), nullable=True))

    op.create_table(
        "havok_hulls",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("block_id", sa.Integer(), sa.ForeignKey("blocks.id"), nullable=False),
        sa.Column("slice_index", sa.Integer(), nullable=True),
        sa.Column("hull_index", sa.Integer(), nullable=True),
        sa.Column("vertex_count", sa.Integer(), nullable=True),
        sa.Column("plane_count", sa.Integer(), nullable=True),
        sa.Column("obj_filename", sa.Text(), nullable=True),
    )
    op.create_index("ix_havok_hulls_block_id", "havok_hulls", ["block_id"])
    op.create_index("ix_havok_hulls_vertex_count", "havok_hulls", ["vertex_count"])


def downgrade() -> None:
    op.drop_index("ix_havok_hulls_vertex_count", table_name="havok_hulls")
    op.drop_index("ix_havok_hulls_block_id", table_name="havok_hulls")
    op.drop_table("havok_hulls")
    op.drop_column("havok_slices", "mesh_count")
    op.drop_column("havok_slices", "mopp_count")
    op.drop_column("havok_slices", "box_count")
    op.drop_column("havok_slices", "convex_hull_count")
    op.drop_column("havok_slices", "class_counts")
