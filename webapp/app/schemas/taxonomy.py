from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class CategoryBase(BaseModel):
    name: str
    slug: str
    parent_id: int | None = None
    depth: int = 0
    path: str | None = None
    description: str | None = None
    color_hex: str | None = None
    icon: str | None = None
    auto_pattern: str | None = None
    sort_order: int = 0


class CategoryCreate(CategoryBase):
    pass


class CategoryRead(CategoryBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime | None = None


class TagBase(BaseModel):
    name: str
    slug: str
    color_hex: str | None = None


class TagCreate(TagBase):
    pass


class TagRead(TagBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime | None = None


class FactionBase(BaseModel):
    code: str
    name: str
    color_hex: str | None = None
    description: str | None = None


class FactionCreate(FactionBase):
    pass


class FactionRead(FactionBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
