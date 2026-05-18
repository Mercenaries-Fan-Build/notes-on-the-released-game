from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import PaginationParams
from app.models import Category, Faction, Tag
from app.schemas.common import PaginatedResponse
from app.schemas.taxonomy import (
    CategoryCreate,
    CategoryRead,
    FactionCreate,
    FactionRead,
    TagCreate,
    TagRead,
)

router = APIRouter(tags=["taxonomy"])

# ---------- Categories ----------

cat_router = APIRouter(prefix="/categories", tags=["categories"])


@cat_router.get("", response_model=list[CategoryRead])
async def list_categories(db: AsyncSession = Depends(get_db)):
    q = select(Category).order_by(Category.sort_order, Category.name)
    return (await db.execute(q)).scalars().all()


@cat_router.get("/{cat_id}", response_model=CategoryRead)
async def get_category(cat_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Category, cat_id)
    if not row:
        raise HTTPException(404, "Category not found")
    return row


@cat_router.post("", response_model=CategoryRead, status_code=201)
async def create_category(body: CategoryCreate, db: AsyncSession = Depends(get_db)):
    obj = Category(**body.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


@cat_router.delete("/{cat_id}", status_code=204)
async def delete_category(cat_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Category, cat_id)
    if not row:
        raise HTTPException(404, "Category not found")
    await db.delete(row)
    await db.commit()


# ---------- Tags ----------

tag_router = APIRouter(prefix="/tags", tags=["tags"])


@tag_router.get("", response_model=list[TagRead])
async def list_tags(db: AsyncSession = Depends(get_db)):
    q = select(Tag).order_by(Tag.name)
    return (await db.execute(q)).scalars().all()


@tag_router.post("", response_model=TagRead, status_code=201)
async def create_tag(body: TagCreate, db: AsyncSession = Depends(get_db)):
    obj = Tag(**body.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


@tag_router.delete("/{tag_id}", status_code=204)
async def delete_tag(tag_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Tag, tag_id)
    if not row:
        raise HTTPException(404, "Tag not found")
    await db.delete(row)
    await db.commit()


# ---------- Factions ----------

faction_router = APIRouter(prefix="/factions", tags=["factions"])


@faction_router.get("", response_model=list[FactionRead])
async def list_factions(db: AsyncSession = Depends(get_db)):
    q = select(Faction).order_by(Faction.code)
    return (await db.execute(q)).scalars().all()


@faction_router.get("/{faction_id}", response_model=FactionRead)
async def get_faction(faction_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Faction, faction_id)
    if not row:
        raise HTTPException(404, "Faction not found")
    return row


@faction_router.post("", response_model=FactionRead, status_code=201)
async def create_faction(body: FactionCreate, db: AsyncSession = Depends(get_db)):
    obj = Faction(**body.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj
