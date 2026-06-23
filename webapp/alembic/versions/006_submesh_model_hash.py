"""Submesh model attribution: model_hash column

Each submesh now carries the asset hash of the model it belongs to (stamped by
tools/mesh_extractor.py). This backs the model-centric workbench: a block holds
many models, and grouping submeshes by model_hash gives the real entities.

Revision ID: 006
Revises: 005
Create Date: 2026-06-21

"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "006"
down_revision: Union[str, None] = "005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("submeshes", sa.Column("model_hash", sa.Text(), nullable=True))
    op.create_index("ix_submeshes_model_hash", "submeshes", ["model_hash"])


def downgrade() -> None:
    op.drop_index("ix_submeshes_model_hash", table_name="submeshes")
    op.drop_column("submeshes", "model_hash")
