from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import PaginationParams, PlacementFilterParams
from app.models import Placement, VzStateOverlay
from app.schemas.common import PaginatedResponse
from app.schemas.placement import (
    PlacementCreate,
    PlacementRead,
    PlacementUpdate,
    VzStateOverlayCreate,
    VzStateOverlayRead,
)

router = APIRouter(prefix="/placements", tags=["placements"])


def _apply_placement_filters(stmt, filters: PlacementFilterParams):
    if filters.search:
        stmt = stmt.where(Placement.entity_name.ilike(f"%{filters.search}%"))
    if filters.block_type:
        stmt = stmt.where(Placement.block_type == filters.block_type)
    if filters.category_id is not None:
        stmt = stmt.where(Placement.category_id == filters.category_id)
    if filters.vz_state_overlay_id is not None:
        stmt = stmt.where(Placement.vz_state_overlay_id == filters.vz_state_overlay_id)
    if filters.linked_block_id is not None:
        stmt = stmt.where(Placement.linked_block_id == filters.linked_block_id)
    if filters.visibility_default is not None:
        stmt = stmt.where(Placement.visibility_default == filters.visibility_default)
    return stmt


@router.get("", response_model=PaginatedResponse[PlacementRead])
async def list_placements(
    pag: PaginationParams = Depends(),
    filters: PlacementFilterParams = Depends(),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(Placement)
    count_q = _apply_placement_filters(count_q, filters)
    total = (await db.execute(count_q)).scalar_one()

    q = select(Placement).order_by(Placement.id)
    q = _apply_placement_filters(q, filters)
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@router.get("/{placement_id}", response_model=PlacementRead)
async def get_placement(placement_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Placement, placement_id)
    if not row:
        raise HTTPException(404, "Placement not found")
    return row


@router.post("", response_model=PlacementRead, status_code=201)
async def create_placement(body: PlacementCreate, db: AsyncSession = Depends(get_db)):
    obj = Placement(**body.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


@router.patch("/{placement_id}", response_model=PlacementRead)
async def update_placement(
    placement_id: int, body: PlacementUpdate, db: AsyncSession = Depends(get_db)
):
    row = await db.get(Placement, placement_id)
    if not row:
        raise HTTPException(404, "Placement not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(row, k, v)
    await db.commit()
    await db.refresh(row)
    return row


@router.delete("/{placement_id}", status_code=204)
async def delete_placement(placement_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Placement, placement_id)
    if not row:
        raise HTTPException(404, "Placement not found")
    await db.delete(row)
    await db.commit()


# ----------- VZ State Overlays -----------

overlay_router = APIRouter(prefix="/vz-state-overlays", tags=["vz-state-overlays"])


@overlay_router.get("", response_model=PaginatedResponse[VzStateOverlayRead])
async def list_overlays(
    pag: PaginationParams = Depends(),
    faction: str | None = None,
    stage: str | None = None,
    act: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(VzStateOverlay)
    q = select(VzStateOverlay).order_by(VzStateOverlay.id)
    if faction:
        count_q = count_q.where(VzStateOverlay.faction == faction)
        q = q.where(VzStateOverlay.faction == faction)
    if stage:
        count_q = count_q.where(VzStateOverlay.stage == stage)
        q = q.where(VzStateOverlay.stage == stage)
    if act:
        count_q = count_q.where(VzStateOverlay.act == act)
        q = q.where(VzStateOverlay.act == act)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@overlay_router.get("/{overlay_id}", response_model=VzStateOverlayRead)
async def get_overlay(overlay_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(VzStateOverlay, overlay_id)
    if not row:
        raise HTTPException(404, "VzStateOverlay not found")
    return row


@overlay_router.get("/{overlay_id}/placements", response_model=PaginatedResponse[PlacementRead])
async def get_overlay_placements(
    overlay_id: int,
    pag: PaginationParams = Depends(),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(Placement).where(
        Placement.vz_state_overlay_id == overlay_id
    )
    total = (await db.execute(count_q)).scalar_one()
    q = (
        select(Placement)
        .where(Placement.vz_state_overlay_id == overlay_id)
        .order_by(Placement.id)
        .offset(pag.offset)
        .limit(pag.limit)
    )
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)
