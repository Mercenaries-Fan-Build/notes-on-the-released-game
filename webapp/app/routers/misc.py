from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import PaginationParams
from app.models import (
    AsetRow,
    DialogFragment,
    HavokSlice,
    LuaChunk,
    Mission,
    SaveProfile,
    ValidationResult,
)
from app.schemas.common import PaginatedResponse
from app.schemas.misc import (
    AsetRowRead,
    DialogFragmentRead,
    HavokSliceRead,
    LuaChunkRead,
    MissionRead,
    SaveProfileRead,
    ValidationResultRead,
)

router = APIRouter(tags=["misc"])

# ---------- ASET Rows ----------

aset_router = APIRouter(prefix="/aset-rows", tags=["aset"])


@aset_router.get("", response_model=PaginatedResponse[AsetRowRead])
async def list_aset_rows(
    pag: PaginationParams = Depends(),
    texture_index_hit: bool | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(AsetRow)
    q = select(AsetRow).order_by(AsetRow.row_index)
    if texture_index_hit is not None:
        count_q = count_q.where(AsetRow.texture_index_hit == texture_index_hit)
        q = q.where(AsetRow.texture_index_hit == texture_index_hit)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


# ---------- Missions ----------

missions_router = APIRouter(prefix="/missions", tags=["missions"])


@missions_router.get("", response_model=PaginatedResponse[MissionRead])
async def list_missions(
    pag: PaginationParams = Depends(),
    faction: str | None = Query(default=None),
    type: str | None = Query(default=None),
    act: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(Mission)
    q = select(Mission).order_by(Mission.mission_id)
    if faction:
        count_q = count_q.where(Mission.faction == faction)
        q = q.where(Mission.faction == faction)
    if type:
        count_q = count_q.where(Mission.type == type)
        q = q.where(Mission.type == type)
    if act:
        count_q = count_q.where(Mission.act == act)
        q = q.where(Mission.act == act)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@missions_router.get("/{mission_id}", response_model=MissionRead)
async def get_mission(mission_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Mission, mission_id)
    if not row:
        raise HTTPException(404, "Mission not found")
    return row


# ---------- Dialog Fragments ----------

dialog_router = APIRouter(prefix="/dialog-fragments", tags=["dialog"])


@dialog_router.get("", response_model=PaginatedResponse[DialogFragmentRead])
async def list_dialog_fragments(
    pag: PaginationParams = Depends(),
    fragment_type: str | None = Query(default=None),
    block_id: int | None = Query(default=None),
    search: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(DialogFragment)
    q = select(DialogFragment).order_by(DialogFragment.id)
    if fragment_type:
        count_q = count_q.where(DialogFragment.fragment_type == fragment_type)
        q = q.where(DialogFragment.fragment_type == fragment_type)
    if block_id is not None:
        count_q = count_q.where(DialogFragment.block_id == block_id)
        q = q.where(DialogFragment.block_id == block_id)
    if search:
        count_q = count_q.where(DialogFragment.value.ilike(f"%{search}%"))
        q = q.where(DialogFragment.value.ilike(f"%{search}%"))

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


# ---------- Lua Chunks ----------

lua_router = APIRouter(prefix="/lua-chunks", tags=["lua"])


@lua_router.get("", response_model=PaginatedResponse[LuaChunkRead])
async def list_lua_chunks(
    pag: PaginationParams = Depends(),
    block_id: int | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(LuaChunk)
    q = select(LuaChunk).order_by(LuaChunk.id)
    if block_id is not None:
        count_q = count_q.where(LuaChunk.block_id == block_id)
        q = q.where(LuaChunk.block_id == block_id)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


# ---------- Havok Slices ----------

havok_router = APIRouter(prefix="/havok-slices", tags=["havok"])


@havok_router.get("", response_model=PaginatedResponse[HavokSliceRead])
async def list_havok_slices(
    pag: PaginationParams = Depends(),
    block_id: int | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(HavokSlice)
    q = select(HavokSlice).order_by(HavokSlice.id)
    if block_id is not None:
        count_q = count_q.where(HavokSlice.block_id == block_id)
        q = q.where(HavokSlice.block_id == block_id)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


# ---------- Save Profiles ----------

save_router = APIRouter(prefix="/save-profiles", tags=["saves"])


@save_router.get("", response_model=list[SaveProfileRead])
async def list_save_profiles(db: AsyncSession = Depends(get_db)):
    q = select(SaveProfile).order_by(SaveProfile.id)
    return (await db.execute(q)).scalars().all()


@save_router.get("/{profile_id}", response_model=SaveProfileRead)
async def get_save_profile(profile_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(SaveProfile, profile_id)
    if not row:
        raise HTTPException(404, "SaveProfile not found")
    return row


# ---------- Validation Results ----------

validation_router = APIRouter(prefix="/validation-results", tags=["validation"])


@validation_router.get("", response_model=PaginatedResponse[ValidationResultRead])
async def list_validation_results(
    pag: PaginationParams = Depends(),
    check_name: str | None = Query(default=None),
    status: str | None = Query(default=None),
    block_id: int | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(ValidationResult)
    q = select(ValidationResult).order_by(ValidationResult.run_at.desc())
    if check_name:
        count_q = count_q.where(ValidationResult.check_name == check_name)
        q = q.where(ValidationResult.check_name == check_name)
    if status:
        count_q = count_q.where(ValidationResult.status == status)
        q = q.where(ValidationResult.status == status)
    if block_id is not None:
        count_q = count_q.where(ValidationResult.block_id == block_id)
        q = q.where(ValidationResult.block_id == block_id)

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)
