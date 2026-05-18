from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import PaginationParams
from app.models import Spawner, Spline, TerrainTile, WorldCell, Zone
from app.schemas.common import PaginatedResponse
from app.schemas.world import (
    SpawnerCreate,
    SpawnerRead,
    SplineCreate,
    SplineRead,
    TerrainTileRead,
    WorldCellRead,
    ZoneCreate,
    ZoneRead,
    ZoneUpdate,
)

router = APIRouter(tags=["world"])

# ---------- World Cells ----------

cells_router = APIRouter(prefix="/world-cells", tags=["world-cells"])


@cells_router.get("", response_model=PaginatedResponse[WorldCellRead])
async def list_world_cells(
    pag: PaginationParams = Depends(),
    db: AsyncSession = Depends(get_db),
):
    total = (await db.execute(select(func.count()).select_from(WorldCell))).scalar_one()
    q = select(WorldCell).order_by(WorldCell.cell_id).offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@cells_router.get("/{cell_id}", response_model=WorldCellRead)
async def get_world_cell(cell_id: int, db: AsyncSession = Depends(get_db)):
    q = select(WorldCell).where(WorldCell.cell_id == cell_id)
    row = (await db.execute(q)).scalar_one_or_none()
    if not row:
        raise HTTPException(404, "WorldCell not found")
    return row


# ---------- Terrain Tiles ----------

terrain_router = APIRouter(prefix="/terrain-tiles", tags=["terrain"])


@terrain_router.get("", response_model=PaginatedResponse[TerrainTileRead])
async def list_terrain_tiles(
    pag: PaginationParams = Depends(),
    db: AsyncSession = Depends(get_db),
):
    total = (await db.execute(select(func.count()).select_from(TerrainTile))).scalar_one()
    q = select(TerrainTile).order_by(TerrainTile.id).offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


# ---------- Zones ----------

zones_router = APIRouter(prefix="/zones", tags=["zones"])


@zones_router.get("", response_model=PaginatedResponse[ZoneRead])
async def list_zones(
    pag: PaginationParams = Depends(),
    zone_type: str | None = Query(default=None),
    faction_id: int | None = Query(default=None),
    is_active: bool | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(Zone)
    q = select(Zone).order_by(Zone.sort_order, Zone.name)
    if zone_type:
        count_q = count_q.where(Zone.zone_type == zone_type)
        q = q.where(Zone.zone_type == zone_type)
    if faction_id is not None:
        count_q = count_q.where(Zone.faction_id == faction_id)
        q = q.where(Zone.faction_id == faction_id)
    if is_active is not None:
        count_q = count_q.where(Zone.is_active == is_active)
        q = q.where(Zone.is_active == is_active)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@zones_router.get("/{zone_id}", response_model=ZoneRead)
async def get_zone(zone_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Zone, zone_id)
    if not row:
        raise HTTPException(404, "Zone not found")
    return row


@zones_router.post("", response_model=ZoneRead, status_code=201)
async def create_zone(body: ZoneCreate, db: AsyncSession = Depends(get_db)):
    obj = Zone(**body.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


@zones_router.patch("/{zone_id}", response_model=ZoneRead)
async def update_zone(
    zone_id: int, body: ZoneUpdate, db: AsyncSession = Depends(get_db)
):
    row = await db.get(Zone, zone_id)
    if not row:
        raise HTTPException(404, "Zone not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(row, k, v)
    await db.commit()
    await db.refresh(row)
    return row


@zones_router.delete("/{zone_id}", status_code=204)
async def delete_zone(zone_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Zone, zone_id)
    if not row:
        raise HTTPException(404, "Zone not found")
    await db.delete(row)
    await db.commit()


# ---------- Splines ----------

splines_router = APIRouter(prefix="/splines", tags=["splines"])


@splines_router.get("", response_model=PaginatedResponse[SplineRead])
async def list_splines(
    pag: PaginationParams = Depends(),
    spline_type: str | None = Query(default=None),
    zone_id: int | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(Spline)
    q = select(Spline).order_by(Spline.id)
    if spline_type:
        count_q = count_q.where(Spline.spline_type == spline_type)
        q = q.where(Spline.spline_type == spline_type)
    if zone_id is not None:
        count_q = count_q.where(Spline.zone_id == zone_id)
        q = q.where(Spline.zone_id == zone_id)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@splines_router.post("", response_model=SplineRead, status_code=201)
async def create_spline(body: SplineCreate, db: AsyncSession = Depends(get_db)):
    obj = Spline(**body.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


@splines_router.get("/{spline_id}", response_model=SplineRead)
async def get_spline(spline_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Spline, spline_id)
    if not row:
        raise HTTPException(404, "Spline not found")
    return row


@splines_router.patch("/{spline_id}", response_model=SplineRead)
async def update_spline(
    spline_id: int, body: SplineCreate, db: AsyncSession = Depends(get_db)
):
    row = await db.get(Spline, spline_id)
    if not row:
        raise HTTPException(404, "Spline not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(row, k, v)
    await db.commit()
    await db.refresh(row)
    return row


@splines_router.delete("/{spline_id}", status_code=204)
async def delete_spline(spline_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Spline, spline_id)
    if not row:
        raise HTTPException(404, "Spline not found")
    await db.delete(row)
    await db.commit()


# ---------- Spawners ----------

spawners_router = APIRouter(prefix="/spawners", tags=["spawners"])


@spawners_router.get("", response_model=PaginatedResponse[SpawnerRead])
async def list_spawners(
    pag: PaginationParams = Depends(),
    spawner_type: str | None = Query(default=None),
    zone_id: int | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(Spawner)
    q = select(Spawner).order_by(Spawner.id)
    if spawner_type:
        count_q = count_q.where(Spawner.spawner_type == spawner_type)
        q = q.where(Spawner.spawner_type == spawner_type)
    if zone_id is not None:
        count_q = count_q.where(Spawner.zone_id == zone_id)
        q = q.where(Spawner.zone_id == zone_id)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@spawners_router.post("", response_model=SpawnerRead, status_code=201)
async def create_spawner(body: SpawnerCreate, db: AsyncSession = Depends(get_db)):
    obj = Spawner(**body.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


@spawners_router.get("/{spawner_id}", response_model=SpawnerRead)
async def get_spawner(spawner_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Spawner, spawner_id)
    if not row:
        raise HTTPException(404, "Spawner not found")
    return row


@spawners_router.patch("/{spawner_id}", response_model=SpawnerRead)
async def update_spawner(
    spawner_id: int, body: SpawnerCreate, db: AsyncSession = Depends(get_db)
):
    row = await db.get(Spawner, spawner_id)
    if not row:
        raise HTTPException(404, "Spawner not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(row, k, v)
    await db.commit()
    await db.refresh(row)
    return row


@spawners_router.delete("/{spawner_id}", status_code=204)
async def delete_spawner(spawner_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Spawner, spawner_id)
    if not row:
        raise HTTPException(404, "Spawner not found")
    await db.delete(row)
    await db.commit()
