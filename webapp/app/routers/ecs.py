from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import PaginationParams
from app.models import EcsComponentType, EcsRecord, EcsSymbol
from app.schemas.common import PaginatedResponse
from app.schemas.ecs import (
    EcsComponentTypeCreate,
    EcsComponentTypeRead,
    EcsRecordRead,
    EcsSymbolRead,
)

router = APIRouter(prefix="/ecs", tags=["ecs"])


@router.get("/component-types", response_model=list[EcsComponentTypeRead])
async def list_component_types(
    category: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    q = select(EcsComponentType).order_by(EcsComponentType.name)
    if category:
        q = q.where(EcsComponentType.category == category)
    return (await db.execute(q)).scalars().all()


@router.get("/component-types/{ct_id}", response_model=EcsComponentTypeRead)
async def get_component_type(ct_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(EcsComponentType, ct_id)
    if not row:
        raise HTTPException(404, "EcsComponentType not found")
    return row


@router.post("/component-types", response_model=EcsComponentTypeRead, status_code=201)
async def create_component_type(
    body: EcsComponentTypeCreate, db: AsyncSession = Depends(get_db)
):
    obj = EcsComponentType(**body.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


@router.get("/records", response_model=PaginatedResponse[EcsRecordRead])
async def list_ecs_records(
    pag: PaginationParams = Depends(),
    comp_name: str | None = Query(default=None),
    entity_key: int | None = Query(default=None),
    block_type: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(EcsRecord)
    q = select(EcsRecord).order_by(EcsRecord.id)
    if comp_name:
        count_q = count_q.where(EcsRecord.comp_name == comp_name)
        q = q.where(EcsRecord.comp_name == comp_name)
    if entity_key is not None:
        count_q = count_q.where(EcsRecord.entity_key == entity_key)
        q = q.where(EcsRecord.entity_key == entity_key)
    if block_type:
        count_q = count_q.where(EcsRecord.block_type == block_type)
        q = q.where(EcsRecord.block_type == block_type)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@router.get("/records/{record_id}", response_model=EcsRecordRead)
async def get_ecs_record(record_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(EcsRecord, record_id)
    if not row:
        raise HTTPException(404, "EcsRecord not found")
    return row


@router.get("/symbols", response_model=PaginatedResponse[EcsSymbolRead])
async def list_ecs_symbols(
    pag: PaginationParams = Depends(),
    db: AsyncSession = Depends(get_db),
):
    total = (await db.execute(select(func.count()).select_from(EcsSymbol))).scalar_one()
    q = select(EcsSymbol).order_by(EcsSymbol.id).offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@router.get("/component-summary")
async def ecs_component_summary(db: AsyncSession = Depends(get_db)):
    q = (
        select(EcsRecord.comp_name, func.count())
        .group_by(EcsRecord.comp_name)
        .order_by(func.count().desc())
    )
    rows = (await db.execute(q)).all()
    return [{"comp_name": r[0], "count": r[1]} for r in rows]
