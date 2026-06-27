from __future__ import annotations

from fastapi import Depends, FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models import (
    AnimationGroup,
    AsetRow,
    Block,
    Category,
    DialogFragment,
    EcsRecord,
    Faction,
    LuaChunk,
    Mission,
    Placement,
    Texture,
    VzStateOverlay,
    WadArchive,
    WorldCell,
)
from app.routers.animations import router as animations_router
from app.routers.blocks import router as blocks_router
from app.routers.models import router as models_router
from app.routers.network_captures import router as network_captures_router
from app.routers.ecs import router as ecs_router
from app.routers.misc import (
    aset_router,
    dialog_router,
    havok_router,
    lua_router,
    missions_router,
    save_router,
    validation_router,
)
from app.routers.placements import overlay_router, router as placements_router
from app.routers.taxonomy import cat_router, faction_router, tag_router
from app.routers.textures import router as textures_router
from app.routers.world import (
    cells_router,
    spawners_router,
    splines_router,
    terrain_router,
    zones_router,
)
from app.schemas.common import HealthResponse, StatsResponse

app = FastAPI(
    title="Mercenaries 2 Asset Database API",
    version="0.1.0",
    debug=settings.debug,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

api_prefix = "/api"

app.include_router(blocks_router, prefix=api_prefix)
app.include_router(models_router, prefix=api_prefix)
app.include_router(placements_router, prefix=api_prefix)
app.include_router(overlay_router, prefix=api_prefix)
app.include_router(cat_router, prefix=api_prefix)
app.include_router(tag_router, prefix=api_prefix)
app.include_router(faction_router, prefix=api_prefix)
app.include_router(ecs_router, prefix=api_prefix)
app.include_router(textures_router, prefix=api_prefix)
app.include_router(animations_router, prefix=api_prefix)
app.include_router(cells_router, prefix=api_prefix)
app.include_router(terrain_router, prefix=api_prefix)
app.include_router(zones_router, prefix=api_prefix)
app.include_router(splines_router, prefix=api_prefix)
app.include_router(spawners_router, prefix=api_prefix)
app.include_router(aset_router, prefix=api_prefix)
app.include_router(missions_router, prefix=api_prefix)
app.include_router(dialog_router, prefix=api_prefix)
app.include_router(lua_router, prefix=api_prefix)
app.include_router(havok_router, prefix=api_prefix)
app.include_router(save_router, prefix=api_prefix)
app.include_router(validation_router, prefix=api_prefix)
app.include_router(network_captures_router, prefix=api_prefix)


@app.get("/api/health", response_model=HealthResponse)
async def health_check(db: AsyncSession = Depends(get_db)) -> HealthResponse:
    try:
        await db.execute(select(func.count()).select_from(Block))
        return HealthResponse(status="ok", database="connected")
    except Exception:
        return HealthResponse(status="degraded", database="unreachable")


@app.get("/api/search")
async def global_search(
    q: str = Query(..., min_length=1, description="Search query"),
    limit: int = Query(default=10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
):
    pattern = f"%{q}%"
    blocks_q = (
        select(Block).where(
            Block.canonical_name.ilike(pattern) | Block.stem.ilike(pattern)
        ).order_by(Block.id).limit(limit)
    )
    blocks_count = (await db.execute(
        select(func.count()).select_from(Block).where(
            Block.canonical_name.ilike(pattern) | Block.stem.ilike(pattern)
        )
    )).scalar_one()
    blocks = (await db.execute(blocks_q)).scalars().all()

    placements_q = (
        select(Placement).where(
            Placement.entity_name.ilike(pattern)
        ).order_by(Placement.id).limit(limit)
    )
    placements_count = (await db.execute(
        select(func.count()).select_from(Placement).where(
            Placement.entity_name.ilike(pattern)
        )
    )).scalar_one()
    placements = (await db.execute(placements_q)).scalars().all()

    textures_q = (
        select(Texture).where(
            Texture.name.ilike(pattern)
        ).order_by(Texture.id).limit(limit)
    )
    textures_count = (await db.execute(
        select(func.count()).select_from(Texture).where(
            Texture.name.ilike(pattern)
        )
    )).scalar_one()
    textures = (await db.execute(textures_q)).scalars().all()

    dialog_q = (
        select(DialogFragment).where(
            DialogFragment.value.ilike(pattern)
        ).order_by(DialogFragment.id).limit(limit)
    )
    dialog_count = (await db.execute(
        select(func.count()).select_from(DialogFragment).where(
            DialogFragment.value.ilike(pattern)
        )
    )).scalar_one()
    dialog = (await db.execute(dialog_q)).scalars().all()

    missions_q = (
        select(Mission).where(
            Mission.mission_id.ilike(pattern)
        ).order_by(Mission.mission_id).limit(limit)
    )
    missions_count = (await db.execute(
        select(func.count()).select_from(Mission).where(
            Mission.mission_id.ilike(pattern)
        )
    )).scalar_one()
    missions = (await db.execute(missions_q)).scalars().all()

    return {
        "blocks": {
            "total": blocks_count,
            "items": [
                {
                    "id": b.id, "stem": b.stem, "canonical_name": b.canonical_name,
                    "block_type": b.block_type, "review_status": b.review_status,
                    "has_geometry": b.has_geometry,
                }
                for b in blocks
            ],
        },
        "placements": {
            "total": placements_count,
            "items": [
                {
                    "id": p.id, "entity_name": p.entity_name, "block_type": p.block_type,
                    "pos_x": p.pos_x, "pos_y": p.pos_y, "pos_z": p.pos_z,
                    "vz_state_source": p.vz_state_source,
                }
                for p in placements
            ],
        },
        "textures": {
            "total": textures_count,
            "items": [
                {
                    "id": t.id, "name": t.name, "width": t.width, "height": t.height,
                    "fourcc": t.fourcc, "texture_channel": t.texture_channel,
                }
                for t in textures
            ],
        },
        "dialog": {
            "total": dialog_count,
            "items": [
                {
                    "id": d.id, "value": d.value, "fragment_type": d.fragment_type,
                    "namespace": d.namespace, "block_id": d.block_id,
                    "is_mission_ref": d.is_mission_ref, "is_localization": d.is_localization,
                }
                for d in dialog
            ],
        },
        "missions": {
            "total": missions_count,
            "items": [
                {
                    "id": m.id, "mission_id": m.mission_id, "faction": m.faction,
                    "type": m.type, "act": m.act,
                }
                for m in missions
            ],
        },
    }


@app.get("/api/stats", response_model=StatsResponse)
async def get_stats(db: AsyncSession = Depends(get_db)) -> StatsResponse:
    tables = {
        "blocks": Block,
        "placements": Placement,
        "textures": Texture,
        "categories": Category,
        "ecs_records": EcsRecord,
        "animation_groups": AnimationGroup,
        "world_cells": WorldCell,
        "wad_archives": WadArchive,
        "vz_state_overlays": VzStateOverlay,
        "missions": Mission,
        "factions": Faction,
        "lua_chunks": LuaChunk,
        "dialog_fragments": DialogFragment,
        "aset_rows": AsetRow,
    }
    counts: dict[str, int] = {}
    for key, model in tables.items():
        result = await db.execute(select(func.count()).select_from(model))
        counts[key] = result.scalar_one()
    return StatsResponse(**counts)
