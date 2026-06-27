"""Submesh destruction state: switch_group column

The orchestrator join (tools/destruction_join.py) writes intact|break_piece|static
into the existing submeshes.damage_state column; switch_group ties the pieces of one
intact↔destroyed swap together so the workbench can toggle a single group at a time.

Revision ID: 005
Revises: 004
Create Date: 2026-06-21

"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "005"
down_revision: Union[str, None] = "004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("submeshes", sa.Column("switch_group", sa.Integer(), nullable=True))
    op.create_index("ix_submeshes_damage_state", "submeshes", ["damage_state"])


def downgrade() -> None:
    op.drop_index("ix_submeshes_damage_state", table_name="submeshes")
    op.drop_column("submeshes", "switch_group")
