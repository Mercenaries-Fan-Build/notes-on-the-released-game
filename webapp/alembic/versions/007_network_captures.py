"""Network captures table for the coop / online-service capture server

Backs the standalone ``coopserver`` capture service: every network request the
game makes to Modkit's emulated EA endpoints (FESL auth, ad-serving HTTP,
Theater, raw TCP/UDP) is logged here with full params/headers/body — like
httpbin — covering both the main-menu (shell.wad) and in-game (vz.wad) traffic.

Revision ID: 007
Revises: 006
Create Date: 2026-06-21

"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "007"
down_revision: Union[str, None] = "006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "network_captures",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("protocol", sa.Text(), nullable=False),
        sa.Column("direction", sa.Text(), nullable=True),
        sa.Column("peer_addr", sa.Text(), nullable=True),
        sa.Column("server_port", sa.Integer(), nullable=True),
        sa.Column("host", sa.Text(), nullable=True),
        sa.Column("method", sa.Text(), nullable=True),
        sa.Column("path", sa.Text(), nullable=True),
        sa.Column("fesl_type", sa.Text(), nullable=True),
        sa.Column("fesl_txn", sa.Text(), nullable=True),
        sa.Column("fesl_id", sa.BigInteger(), nullable=True),
        sa.Column("headers", sa.JSON(), nullable=True),
        sa.Column("params", sa.JSON(), nullable=True),
        sa.Column("body_text", sa.Text(), nullable=True),
        sa.Column("body_hex", sa.Text(), nullable=True),
        sa.Column("body_len", sa.Integer(), nullable=True),
        sa.Column("response_summary", sa.Text(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=True,
        ),
    )
    op.create_index("ix_network_captures_protocol", "network_captures", ["protocol"])
    op.create_index("ix_network_captures_host", "network_captures", ["host"])
    op.create_index("ix_network_captures_fesl_txn", "network_captures", ["fesl_txn"])
    op.create_index("ix_network_captures_created_at", "network_captures", ["created_at"])


def downgrade() -> None:
    op.drop_index("ix_network_captures_created_at", table_name="network_captures")
    op.drop_index("ix_network_captures_fesl_txn", table_name="network_captures")
    op.drop_index("ix_network_captures_host", table_name="network_captures")
    op.drop_index("ix_network_captures_protocol", table_name="network_captures")
    op.drop_table("network_captures")
