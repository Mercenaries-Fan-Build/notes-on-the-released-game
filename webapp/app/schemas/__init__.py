from __future__ import annotations

from app.schemas.common import HealthResponse, PaginatedResponse, StatsResponse
from app.schemas.wad import WadArchiveCreate, WadArchiveRead
from app.schemas.block import (
    BlockCreate,
    BlockMeshMetaCreate,
    BlockMeshMetaRead,
    BlockRead,
    BlockUpdate,
    SubmeshCreate,
    SubmeshRead,
)
from app.schemas.taxonomy import (
    CategoryCreate,
    CategoryRead,
    FactionCreate,
    FactionRead,
    TagCreate,
    TagRead,
)
from app.schemas.placement import (
    PlacementCreate,
    PlacementRead,
    PlacementUpdate,
    VzStateOverlayCreate,
    VzStateOverlayRead,
)
from app.schemas.ecs import (
    EcsComponentTypeCreate,
    EcsComponentTypeRead,
    EcsRecordCreate,
    EcsRecordRead,
    EcsSymbolCreate,
    EcsSymbolRead,
)
from app.schemas.texture import (
    TextureCreate,
    TextureIndexEntryCreate,
    TextureIndexEntryRead,
    TextureRead,
)
from app.schemas.animation import (
    AnimationClipCreate,
    AnimationClipRead,
    AnimationGroupCreate,
    AnimationGroupRead,
    BoneCreate,
    BoneRead,
    SkeletonCreate,
    SkeletonRead,
)
from app.schemas.world import (
    SpawnerCreate,
    SpawnerRead,
    SplineCreate,
    SplineRead,
    TerrainTileCreate,
    TerrainTileRead,
    WorldCellCreate,
    WorldCellRead,
    ZoneCreate,
    ZoneRead,
    ZoneUpdate,
)
from app.schemas.misc import (
    AsetRowCreate,
    AsetRowRead,
    AudioArchiveCreate,
    AudioArchiveRead,
    AudioStreamCreate,
    AudioStreamRead,
    CutsceneCreate,
    CutsceneRead,
    DialogFragmentCreate,
    DialogFragmentRead,
    HavokSliceCreate,
    HavokSliceRead,
    LuaChunkCreate,
    LuaChunkRead,
    MissionCreate,
    MissionRead,
    PrecacheSlotCreate,
    PrecacheSlotRead,
    RoadCreate,
    RoadRead,
    RoadIntersectionCreate,
    RoadIntersectionRead,
    SaveHarvestedDataCreate,
    SaveHarvestedDataRead,
    SaveProfileCreate,
    SaveProfileRead,
    ValidationResultCreate,
    ValidationResultRead,
    VariantGroupCreate,
    VariantGroupRead,
)
