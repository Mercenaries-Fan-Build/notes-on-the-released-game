from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict


class AnimationGroupBase(BaseModel):
    slug: str
    block_stem: str | None = None
    block_id: int | None = None
    stem_numeric_id: str | None = None
    bone_count: int | None = None
    clip_count: int | None = None
    track_count: int | None = None
    glb_path: str | None = None
    related_review_keys: Any | None = None
    skeleton_source: str | None = None
    ancestor_count: int | None = None


class AnimationGroupCreate(AnimationGroupBase):
    pass


class AnimationGroupRead(AnimationGroupBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class AnimationClipBase(BaseModel):
    animation_group_id: int
    record_index: int | None = None
    gltf_clip_index: int | None = None
    display_name: str | None = None
    gltf_name: str | None = None
    anim_name_guess: str | None = None
    codec_guess: str | None = None
    pelvis_ty_spread_wavelet_raw: float | None = None
    pelvis_ty_spread_after_sanitize: float | None = None
    pelvis_ty_sanitized: Any | None = None


class AnimationClipCreate(AnimationClipBase):
    pass


class AnimationClipRead(AnimationClipBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class SkeletonBase(BaseModel):
    animation_group_id: int | None = None
    bone_count: int | None = None
    source: str | None = None
    track_count: int | None = None
    ancestor_count: int | None = None
    meta: Any | None = None


class SkeletonCreate(SkeletonBase):
    pass


class SkeletonRead(SkeletonBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class BoneBase(BaseModel):
    skeleton_id: int
    bone_index: int
    bone_name: str | None = None
    parent_index: int | None = None
    ref_pos_x: float | None = None
    ref_pos_y: float | None = None
    ref_pos_z: float | None = None
    ref_quat_x: float | None = None
    ref_quat_y: float | None = None
    ref_quat_z: float | None = None
    ref_quat_w: float | None = None
    ref_scale_x: float | None = None
    ref_scale_y: float | None = None
    ref_scale_z: float | None = None


class BoneCreate(BoneBase):
    pass


class BoneRead(BoneBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
