"""Model-centric endpoints.

A *model* (asset hash) is the workbench's first-class entity. The engine packs
models into blocks (and one block can hold many — resident2 holds ~99), so these
endpoints group `submeshes` by `model_hash` to recover the real entities across
blocks, picking the block that best represents each model as the one to load.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db

router = APIRouter(prefix="/models", tags=["models"])


@router.get("")
async def list_models(
    db: AsyncSession = Depends(get_db),
    q: str | None = Query(None, description="substring filter on model hash / block name"),
    pack: str | None = None,
    destructible: bool | None = Query(None, description="only models with intact/break_piece state"),
    limit: int = Query(200, le=2000),
    offset: int = 0,
):
    """List models (one row per asset hash), with the block that best represents
    each, aggregate counts, and whether it is destructible."""
    where = ["s.model_hash IS NOT NULL"]
    params: dict = {"limit": limit, "offset": offset}
    if q:
        where.append("(s.model_hash ILIKE :q OR b.stem ILIKE :q OR b.canonical_name ILIKE :q)")
        params["q"] = f"%{q}%"
    if pack:
        where.append("b.pack = :pack")
        params["pack"] = pack
    having = ""
    if destructible:
        having = "HAVING bool_or(s.damage_state IN ('intact','break_piece'))"
    sql = text(f"""
        WITH per AS (
            SELECT s.model_hash, s.block_id,
                   count(*) AS sc, coalesce(sum(s.vertex_count),0) AS vc,
                   bool_or(s.damage_state IN ('intact','break_piece')) AS hd
            FROM submeshes s JOIN blocks b ON b.id = s.block_id
            WHERE {' AND '.join(where)}
            GROUP BY s.model_hash, s.block_id
        ),
        agg AS (
            SELECT model_hash,
                   sum(sc) AS submesh_count,
                   count(*) AS block_count,
                   sum(vc) AS vertex_count,
                   bool_or(hd) AS has_destruction,
                   (array_agg(block_id ORDER BY sc DESC))[1] AS primary_block_id
            FROM per GROUP BY model_hash {having}
        )
        SELECT a.model_hash, a.submesh_count, a.block_count, a.vertex_count,
               a.has_destruction, a.primary_block_id,
               b.stem, b.canonical_name, b.pack, b.block_type
        FROM agg a JOIN blocks b ON b.id = a.primary_block_id
        ORDER BY a.submesh_count DESC
        LIMIT :limit OFFSET :offset
    """)
    rows = (await db.execute(sql, params)).mappings().all()
    return {"items": [dict(r) for r in rows], "limit": limit, "offset": offset}


@router.get("/{model_hash}")
async def get_model(model_hash: str, db: AsyncSession = Depends(get_db)):
    """A single model: the blocks that contain it, and the per-block submesh
    breakdown (the viewer loads the primary block's manifest filtered to this
    model_hash for geometry + HIER tree)."""
    blocks = (await db.execute(text("""
        SELECT b.id AS block_id, b.stem, b.canonical_name, b.pack, b.block_type,
               b.review_dir_path,
               count(*) AS submesh_count,
               bool_or(s.damage_state IN ('intact','break_piece')) AS has_destruction
        FROM submeshes s JOIN blocks b ON b.id = s.block_id
        WHERE s.model_hash = :h
        GROUP BY b.id
        ORDER BY submesh_count DESC
    """), {"h": model_hash})).mappings().all()
    if not blocks:
        raise HTTPException(status_code=404, detail="model not found")
    return {
        "model_hash": model_hash,
        "primary_block_id": blocks[0]["block_id"],
        "blocks": [dict(b) for b in blocks],
    }
