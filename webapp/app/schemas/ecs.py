from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict


class EcsComponentTypeBase(BaseModel):
    name: str
    prealloc_primary: int | None = None
    prealloc_secondary: int | None = None
    is_runtime: bool | None = None
    category: str | None = None
    description: str | None = None
    payload_stride: int | None = None


class EcsComponentTypeCreate(EcsComponentTypeBase):
    pass


class EcsComponentTypeRead(EcsComponentTypeBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class EcsRecordBase(BaseModel):
    entity_key: int | None = None
    comp_type_id: int | None = None
    comp_name: str | None = None
    source_block: str | None = None
    block_type: str | None = None
    sub_block: int | None = None
    payload_size: int | None = None
    payload_hex: str | None = None
    placement_id: int | None = None
    model_name_hash: str | None = None
    hibernation_u8_0: int | None = None
    hibernation_u8_1: int | None = None
    hibernation_f16_or_u16: int | None = None
    hibernation_u16_4: int | None = None
    script_hash_0: str | None = None
    script_u32_1: int | None = None
    destruction_ref_key: str | None = None
    destruction_u32_1: int | None = None
    light_u32_0: int | None = None
    light_color_r: int | None = None
    light_color_g: int | None = None
    light_color_b: int | None = None
    light_intensity: float | None = None
    light_radius: float | None = None
    light_radius_ue: float | None = None
    parsed_data: Any | None = None


class EcsRecordCreate(EcsRecordBase):
    pass


class EcsRecordRead(EcsRecordBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class EcsSymbolBase(BaseModel):
    symbol: str | None = None
    symbol_type: str | None = None
    component_hint: str | None = None


class EcsSymbolCreate(EcsSymbolBase):
    pass


class EcsSymbolRead(EcsSymbolBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
