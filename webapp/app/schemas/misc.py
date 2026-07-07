from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class AsetRowBase(BaseModel):
    wad_id: int | None = None
    row_index: int
    u32_0: str | None = None
    u32_0_int: int | None = None
    u32_1: str | None = None
    u32_1_int: int | None = None
    u32_2: str | None = None
    u32_3: int | None = None
    texture_index_hit: bool | None = None
    matched_texture_name: str | None = None
    matched_block_id: int | None = None


class AsetRowCreate(AsetRowBase):
    pass


class AsetRowRead(AsetRowBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class VariantGroupBase(BaseModel):
    base_asset_id: str
    member_count: int | None = None
    best_lod_block_id: int | None = None
    best_lod_vertices: int | None = None


class VariantGroupCreate(VariantGroupBase):
    pass


class VariantGroupRead(VariantGroupBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class HavokSliceBase(BaseModel):
    block_id: int
    slice_index: int | None = None
    file_offset: int | None = None
    size_written: int | None = None
    preview_text: str | None = None
    has_convex_hull: bool | None = None
    convex_hull_filename: str | None = None
    havok_version: str | None = None
    # Structured census from the exact decoder (mercs2_formats::havok).
    class_counts: dict | None = None
    convex_hull_count: int | None = None
    box_count: int | None = None
    mopp_count: int | None = None
    mesh_count: int | None = None


class HavokSliceCreate(HavokSliceBase):
    pass


class HavokSliceRead(HavokSliceBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class HavokHullRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    block_id: int
    slice_index: int | None = None
    hull_index: int | None = None
    vertex_count: int | None = None
    plane_count: int | None = None
    obj_filename: str | None = None


class DialogFragmentBase(BaseModel):
    block_id: int
    fragment_type: str | None = None
    value: str | None = None
    namespace: str | None = None
    key_path: str | None = None
    is_mission_ref: bool | None = None
    is_localization: bool | None = None
    is_objective: bool | None = None
    is_subtitle: bool | None = None
    faction_ref: str | None = None


class DialogFragmentCreate(DialogFragmentBase):
    pass


class DialogFragmentRead(DialogFragmentBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class MissionBase(BaseModel):
    mission_id: str
    faction: str | None = None
    type: str | None = None
    number: int | None = None
    title_key: str | None = None
    has_milestones: bool | None = None
    milestone_count: int | None = None
    act: str | None = None
    region: str | None = None
    related_vz_states: Any | None = None
    objective_keys: Any | None = None
    npc_name: str | None = None
    vo_block_id: int | None = None
    script_chunk_indices: Any | None = None


class MissionCreate(MissionBase):
    pass


class MissionRead(MissionBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class LuaChunkBase(BaseModel):
    block_id: int | None = None
    chunk_index: int | None = None
    byte_offset: int | None = None
    byte_length: int | None = None
    bin_path: str | None = None
    string_count: int | None = None
    pmc_related_strings: Any | None = None
    all_strings: Any | None = None
    mission_refs: Any | None = None
    function_names: Any | None = None


class LuaChunkCreate(LuaChunkBase):
    pass


class LuaChunkRead(LuaChunkBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class AudioArchiveBase(BaseModel):
    name: str | None = None
    file_path: str | None = None
    file_size_bytes: int | None = None
    stream_count: int | None = None


class AudioArchiveCreate(AudioArchiveBase):
    pass


class AudioArchiveRead(AudioArchiveBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class AudioStreamBase(BaseModel):
    archive_id: int
    stream_index: int | None = None
    format: str | None = None
    sample_rate: int | None = None
    channels: int | None = None
    bits_per_sample: int | None = None
    duration_seconds: float | None = None
    byte_rate: int | None = None
    offset_in_archive: int | None = None
    size_bytes: int | None = None
    extracted_path: str | None = None


class AudioStreamCreate(AudioStreamBase):
    pass


class AudioStreamRead(AudioStreamBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class CutsceneBase(BaseModel):
    filename: str | None = None
    file_path: str | None = None
    file_size_bytes: int | None = None
    sequence_number: int | None = None
    scene_code: str | None = None
    character_code: str | None = None
    character_name: str | None = None
    is_menu_video: bool | None = None
    is_cutscene: bool | None = None
    act: str | None = None
    description: str | None = None
    mission_id: str | None = None
    transcript: str | None = None


class CutsceneCreate(CutsceneBase):
    pass


class CutsceneRead(CutsceneBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class SaveProfileBase(BaseModel):
    source_file: str | None = None
    checksum_hex: str | None = None
    version: int | None = None
    character_costume_index: int | None = None
    reference_name: str | None = None
    cash: int | None = None
    fuel: int | None = None
    play_time_seconds: int | None = None
    last_mission_name: str | None = None
    unix_timestamp: int | None = None
    lua_decompressed_chars: int | None = None
    flags_hex: str | None = None
    unknown_0x0C: int | None = None
    unknown_0x10: int | None = None
    unknown_0x20: int | None = None


class SaveProfileCreate(SaveProfileBase):
    pass


class SaveProfileRead(SaveProfileBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class SaveHarvestedDataBase(BaseModel):
    profile_id: int
    data_type: str | None = None
    value: str | None = None


class SaveHarvestedDataCreate(SaveHarvestedDataBase):
    pass


class SaveHarvestedDataRead(SaveHarvestedDataBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class RoadBase(BaseModel):
    entity_key: int | None = None
    placement_id: int | None = None
    payload_hex: str | None = None
    parsed_data: Any | None = None


class RoadCreate(RoadBase):
    pass


class RoadRead(RoadBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class RoadIntersectionBase(BaseModel):
    entity_key: int | None = None
    placement_id: int | None = None
    payload_hex: str | None = None
    parsed_data: Any | None = None


class RoadIntersectionCreate(RoadIntersectionBase):
    pass


class RoadIntersectionRead(RoadIntersectionBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class PrecacheSlotBase(BaseModel):
    slot_number: int
    vertex_size: int | None = None
    index_size: int | None = None
    display_size: int | None = None
    texture_size: int | None = None
    surface_size: int | None = None
    pshader_size: int | None = None
    vshader_size: int | None = None
    vertdecl_size: int | None = None
    total_size: int | None = None


class PrecacheSlotCreate(PrecacheSlotBase):
    pass


class PrecacheSlotRead(PrecacheSlotBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class ValidationResultBase(BaseModel):
    check_name: str | None = None
    block_id: int | None = None
    status: str | None = None
    expected_value: str | None = None
    actual_value: str | None = None
    message: str | None = None


class ValidationResultCreate(ValidationResultBase):
    pass


class ValidationResultRead(ValidationResultBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    run_at: datetime | None = None
