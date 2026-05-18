from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import PaginationParams
from app.models import Texture, TextureIndexEntry
from app.schemas.common import PaginatedResponse
from app.schemas.texture import TextureIndexEntryRead, TextureRead

router = APIRouter(prefix="/textures", tags=["textures"])


@router.get("", response_model=PaginatedResponse[TextureRead])
async def list_textures(
    pag: PaginationParams = Depends(),
    search: str | None = Query(default=None),
    fourcc: str | None = Query(default=None),
    texture_channel: str | None = Query(default=None),
    is_global: bool | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(Texture)
    q = select(Texture).order_by(Texture.name)
    if search:
        count_q = count_q.where(Texture.name.ilike(f"%{search}%"))
        q = q.where(Texture.name.ilike(f"%{search}%"))
    if fourcc:
        count_q = count_q.where(Texture.fourcc == fourcc)
        q = q.where(Texture.fourcc == fourcc)
    if texture_channel:
        count_q = count_q.where(Texture.texture_channel == texture_channel)
        q = q.where(Texture.texture_channel == texture_channel)
    if is_global is not None:
        count_q = count_q.where(Texture.is_global == is_global)
        q = q.where(Texture.is_global == is_global)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@router.get("/index/entries", response_model=PaginatedResponse[TextureIndexEntryRead])
async def list_texture_index(
    pag: PaginationParams = Depends(),
    asset_hash: str | None = Query(default=None),
    texture_name: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(TextureIndexEntry)
    q = select(TextureIndexEntry).order_by(TextureIndexEntry.id)
    if asset_hash:
        count_q = count_q.where(TextureIndexEntry.asset_hash == asset_hash)
        q = q.where(TextureIndexEntry.asset_hash == asset_hash)
    if texture_name:
        count_q = count_q.where(TextureIndexEntry.texture_name.ilike(f"%{texture_name}%"))
        q = q.where(TextureIndexEntry.texture_name.ilike(f"%{texture_name}%"))

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@router.get("/{texture_id}", response_model=TextureRead)
async def get_texture(texture_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Texture, texture_id)
    if not row:
        raise HTTPException(404, "Texture not found")
    return row
