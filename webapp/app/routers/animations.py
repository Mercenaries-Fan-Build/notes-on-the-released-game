from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import PaginationParams
from app.models import AnimationClip, AnimationGroup, Bone, Skeleton
from app.schemas.animation import (
    AnimationClipRead,
    AnimationGroupRead,
    BoneRead,
    SkeletonRead,
)
from app.schemas.common import PaginatedResponse

router = APIRouter(prefix="/animations", tags=["animations"])


@router.get("/groups", response_model=PaginatedResponse[AnimationGroupRead])
async def list_animation_groups(
    pag: PaginationParams = Depends(),
    search: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    count_q = select(func.count()).select_from(AnimationGroup)
    q = select(AnimationGroup).order_by(AnimationGroup.slug)
    if search:
        count_q = count_q.where(AnimationGroup.slug.ilike(f"%{search}%"))
        q = q.where(AnimationGroup.slug.ilike(f"%{search}%"))

    total = (await db.execute(count_q)).scalar_one()
    q = q.offset(pag.offset).limit(pag.limit)
    rows = (await db.execute(q)).scalars().all()
    return PaginatedResponse(items=rows, total=total, offset=pag.offset, limit=pag.limit)


@router.get("/groups/{group_id}", response_model=AnimationGroupRead)
async def get_animation_group(group_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(AnimationGroup, group_id)
    if not row:
        raise HTTPException(404, "AnimationGroup not found")
    return row


@router.get("/groups/{group_id}/clips", response_model=list[AnimationClipRead])
async def get_group_clips(group_id: int, db: AsyncSession = Depends(get_db)):
    q = (
        select(AnimationClip)
        .where(AnimationClip.animation_group_id == group_id)
        .order_by(AnimationClip.record_index)
    )
    return (await db.execute(q)).scalars().all()


@router.get("/groups/{group_id}/skeletons", response_model=list[SkeletonRead])
async def get_group_skeletons(group_id: int, db: AsyncSession = Depends(get_db)):
    q = select(Skeleton).where(Skeleton.animation_group_id == group_id)
    return (await db.execute(q)).scalars().all()


@router.get("/skeletons/{skeleton_id}", response_model=SkeletonRead)
async def get_skeleton(skeleton_id: int, db: AsyncSession = Depends(get_db)):
    row = await db.get(Skeleton, skeleton_id)
    if not row:
        raise HTTPException(404, "Skeleton not found")
    return row


@router.get("/skeletons/{skeleton_id}/bones", response_model=list[BoneRead])
async def get_skeleton_bones(skeleton_id: int, db: AsyncSession = Depends(get_db)):
    q = select(Bone).where(Bone.skeleton_id == skeleton_id).order_by(Bone.bone_index)
    return (await db.execute(q)).scalars().all()
