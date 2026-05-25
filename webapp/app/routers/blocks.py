from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import BlockFilterParams, PaginationParams
from app.models import Block, BlockMeshMeta, BlockTag, Submesh, Tag
from app.schemas.block import (
    BlockCreate,
    BlockMeshMetaRead,
    BlockRead,
    BlockUpdate,
    SubmeshRead,
)
from app.schemas.common import PaginatedResponse

router = APIRouter(prefix="/blocks", tags=["blocks"])


class BulkUpdateRequest(BaseModel):
    block_ids: list[int]
    review_status: str | None = None
    category_id: int | None = None
    reviewed_by: str | None = None


def _apply_block_filters(stmt, filters: BlockFilterParams):
    if filters.search:
        pattern = f"%{filters.search}%"
        stmt = stmt.where(
            Block.canonical_name.ilike(pattern) | Block.stem.ilike(pattern)
        )
    if filters.block_type:
        stmt = stmt.where(Block.block_type == filters.block_type)
    if filters.category_id is not None:
        stmt = stmt.where(Block.category_id == filters.category_id)
    if filters.has_geometry is not None:
        stmt = stmt.where(Block.has_geometry == filters.has_geometry)
    if filters.has_textures is not None:
        stmt = stmt.where(Block.has_textures == filters.has_textures)
    if filters.has_animations is not None:
        stmt = stmt.where(Block.has_animations == filters.has_animations)
    if filters.review_status:
        stmt = stmt.where(Block.review_status == filters.review_status)
    if filters.faction_hint:
        stmt = stmt.where(Block.faction_hint == filters.faction_hint)
    if filters.region_hint:
        stmt = stmt.where(Block.region_hint == filters.region_hint)
    return stmt


@router.get("", response_model=PaginatedResponse[BlockRead])
async def list_blocks(
    pag: PaginationParams = Depends(),
    filters: BlockFilterParams = Depends(),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(Block)
    count_q = _apply_block_filters(count_q, filters)
    total = (await db.execute(count_q)).scalar_one()

    q = select(Block).order_by(Block.id)
    q = _apply_block_filters(q, filters)
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@router.get("/types/summary")
async def block_type_summary(db: AsyncSession = Depends(get_db)):
    q = (
        select(Block.block_type, func.count())
        .group_by(Block.block_type)
        .order_by(func.count().desc())
    )
    rows = (await db.execute(q)).all()
    return [{"block_type": r[0], "count": r[1]} for r in rows]


@router.get("/review-status/summary")
async def review_status_summary(db: AsyncSession = Depends(get_db)):
    q = (
        select(Block.review_status, func.count())
        .group_by(Block.review_status)
        .order_by(func.count().desc())
    )
    rows = (await db.execute(q)).all()
    return [{"review_status": r[0], "count": r[1]} for r in rows]


@router.post("/bulk-update")
async def bulk_update_blocks(body: BulkUpdateRequest, db: AsyncSession = Depends(get_db)):
    if not body.block_ids:
        return {"updated": 0}
    updated = 0
    for bid in body.block_ids:
        row = await db.get(Block, bid)
        if not row:
            continue
        if body.review_status is not None:
            row.review_status = body.review_status
        if body.category_id is not None:
            row.category_id = body.category_id
        if body.reviewed_by is not None:
            row.reviewed_by = body.reviewed_by
        row.reviewed_at = datetime.now(timezone.utc)
        row.updated_at = datetime.now(timezone.utc)
        updated += 1
    await db.commit()
    return {"updated": updated}


@router.get("/{block_id}", response_model=BlockRead)
async def get_block(block_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Block, block_id)
    if not row:
        raise HTTPException(404, "Block not found")
    return row


@router.post("", response_model=BlockRead, status_code=201)
async def create_block(body: BlockCreate, db: AsyncSession = Depends(get_db)):
    obj = Block(**body.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


@router.patch("/{block_id}", response_model=BlockRead)
async def update_block(
    block_id: int, body: BlockUpdate, db: AsyncSession = Depends(get_db)
):
    row = await db.get(Block, block_id)
    if not row:
        raise HTTPException(404, "Block not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(row, k, v)
    await db.commit()
    await db.refresh(row)
    return row


@router.delete("/{block_id}", status_code=204)
async def delete_block(block_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Block, block_id)
    if not row:
        raise HTTPException(404, "Block not found")
    await db.delete(row)
    await db.commit()


@router.get("/{block_id}/mesh-meta", response_model=BlockMeshMetaRead)
async def get_block_mesh_meta(block_id: int, db: AsyncSession = Depends(get_db)):
    q = select(BlockMeshMeta).where(BlockMeshMeta.block_id == block_id)
    row = (await db.execute(q)).scalar_one_or_none()
    if not row:
        raise HTTPException(404, "Mesh meta not found for this block")
    return row


@router.get("/{block_id}/mesh-meta-raw")
async def get_block_mesh_meta_raw(block_id: int, db: AsyncSession = Depends(get_db)):
    """Stream the full mesh.meta.json file from disk (for large files not stored in DB)."""
    from pathlib import Path

    from fastapi.responses import FileResponse

    q = select(BlockMeshMeta).where(BlockMeshMeta.block_id == block_id)
    row = (await db.execute(q)).scalar_one_or_none()
    if not row:
        raise HTTPException(404, "Mesh meta not found for this block")
    if not row.mesh_meta_path:
        raise HTTPException(404, "No mesh meta file path stored for this block")
    p = Path(row.mesh_meta_path)
    if not p.exists():
        raise HTTPException(404, f"Mesh meta file not found on disk: {p}")
    return FileResponse(str(p), media_type="application/json")


@router.get("/{block_id}/submeshes", response_model=list[SubmeshRead])
async def get_block_submeshes(block_id: int, db: AsyncSession = Depends(get_db)):
    q = select(Submesh).where(Submesh.block_id == block_id).order_by(Submesh.submesh_index)
    return (await db.execute(q)).scalars().all()


@router.get("/{block_id}/textures")
async def get_block_textures(block_id: int, db: AsyncSession = Depends(get_db)):
    from app.models import BlockTexture, Texture
    q = (
        select(Texture, BlockTexture.is_shared, BlockTexture.is_local)
        .join(BlockTexture, BlockTexture.texture_id == Texture.id)
        .where(BlockTexture.block_id == block_id)
        .order_by(Texture.name)
    )
    rows = (await db.execute(q)).all()
    return [
        {
            "id": r[0].id, "name": r[0].name, "asset_hash": r[0].asset_hash,
            "width": r[0].width, "height": r[0].height, "fourcc": r[0].fourcc,
            "texture_channel": r[0].texture_channel, "is_global": r[0].is_global,
            "is_shared": r[1], "is_local": r[2],
        }
        for r in rows
    ]


@router.get("/{block_id}/placements")
async def get_block_placements(
    block_id: int,
    pag: PaginationParams = Depends(),
    db: AsyncSession = Depends(get_db),
):
    from app.models import Placement
    count_q = select(func.count()).select_from(Placement).where(
        Placement.linked_block_id == block_id
    )
    total = (await db.execute(count_q)).scalar_one()
    q = (
        select(Placement)
        .where(Placement.linked_block_id == block_id)
        .order_by(Placement.id)
        .offset(pag.offset).limit(pag.limit)
    )
    rows = (await db.execute(q)).scalars().all()
    from app.schemas.placement import PlacementRead
    from app.schemas.common import PaginatedResponse
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@router.get("/{block_id}/variants")
async def get_block_variants(block_id: int, db: AsyncSession = Depends(get_db)):
    from app.models import VariantGroupMember, VariantGroup
    member = (await db.execute(
        select(VariantGroupMember).where(VariantGroupMember.block_id == block_id)
    )).scalar_one_or_none()
    if not member:
        return {"group": None, "siblings": []}
    group = await db.get(VariantGroup, member.group_id)
    siblings_q = (
        select(VariantGroupMember, Block)
        .join(Block, Block.id == VariantGroupMember.block_id)
        .where(VariantGroupMember.group_id == member.group_id)
        .order_by(VariantGroupMember.p_level, VariantGroupMember.q_level)
    )
    siblings = (await db.execute(siblings_q)).all()
    return {
        "group": {
            "id": group.id if group else None,
            "base_asset_id": group.base_asset_id if group else None,
            "member_count": group.member_count if group else None,
            "best_lod_block_id": group.best_lod_block_id if group else None,
        },
        "siblings": [
            {
                "block_id": s[0].block_id, "p_level": s[0].p_level,
                "q_level": s[0].q_level, "variant_type": s[0].variant_type,
                "stem": s[1].stem, "canonical_name": s[1].canonical_name,
                "has_geometry": s[1].has_geometry,
            }
            for s in siblings
        ],
    }


@router.get("/{block_id}/havok")
async def get_block_havok(block_id: int, db: AsyncSession = Depends(get_db)):
    from app.models import HavokSlice
    q = select(HavokSlice).where(HavokSlice.block_id == block_id).order_by(HavokSlice.slice_index)
    return (await db.execute(q)).scalars().all()


@router.get("/{block_id}/dialog")
async def get_block_dialog(block_id: int, db: AsyncSession = Depends(get_db)):
    from app.models import DialogFragment
    q = select(DialogFragment).where(DialogFragment.block_id == block_id).order_by(DialogFragment.id)
    return (await db.execute(q)).scalars().all()


@router.get("/{block_id}/tags")
async def get_block_tags(block_id: int, db: AsyncSession = Depends(get_db)):
    q = (
        select(Tag)
        .join(BlockTag, BlockTag.tag_id == Tag.id)
        .where(BlockTag.block_id == block_id)
        .order_by(Tag.name)
    )
    return (await db.execute(q)).scalars().all()


@router.post("/{block_id}/tags/{tag_id}", status_code=201)
async def add_block_tag(block_id: int, tag_id: int, db: AsyncSession = Depends(get_db)):
    block = await db.get(Block, block_id)
    if not block:
        raise HTTPException(404, "Block not found")
    tag = await db.get(Tag, tag_id)
    if not tag:
        raise HTTPException(404, "Tag not found")
    existing = (await db.execute(
        select(BlockTag).where(BlockTag.block_id == block_id, BlockTag.tag_id == tag_id)
    )).scalar_one_or_none()
    if existing:
        return {"status": "already_exists"}
    bt = BlockTag(block_id=block_id, tag_id=tag_id)
    db.add(bt)
    await db.commit()
    return {"status": "added"}


@router.delete("/{block_id}/tags/{tag_id}", status_code=204)
async def remove_block_tag(block_id: int, tag_id: int, db: AsyncSession = Depends(get_db)):
    bt = (await db.execute(
        select(BlockTag).where(BlockTag.block_id == block_id, BlockTag.tag_id == tag_id)
    )).scalar_one_or_none()
    if not bt:
        raise HTTPException(404, "Tag not linked to block")
    await db.delete(bt)
    await db.commit()
